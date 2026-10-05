// TOP LEVEL - 5-stage pipelined RV32I core with 2-bit branch prediction
//
// Memories live outside the core (see verif/tb/tb_memory.sv). Both memory
// ports are synchronous-read, SRAM style: the address presented at a clock
// edge returns its data during the following cycle.
//   - IMEM: the *next* PC is presented as the address, so the instruction for
//           pc_current is on imem_rdata during IF.
//   - DMEM: address / write strobes are issued from EX, load data arrives in
//           MEM. Stores commit at the EX->MEM edge (nothing in EX or later is
//           ever squashed, since branches resolve in ID).
//
// Signals marked "trace only" have no fanout inside the core; they exist so
// the testbench can log retired instructions, and synthesis removes them.
module riscv_core #(
    parameter [31:0] RESET_VECTOR = 32'h8000_0000
)(
    input         clk,
    input         rst,          // active-low synchronous reset

    // Instruction memory port
    output [31:0] imem_addr,
    input  [31:0] imem_rdata,

    // Data memory port
    output        dmem_re,
    output [3:0]  dmem_we,      // byte write strobes
    output [31:0] dmem_addr,    // byte address
    output [31:0] dmem_wdata,   // already shifted onto byte lanes
    input  [31:0] dmem_rdata
);

// ============================================================
// All pipeline register declarations up front (declare-before-use)
// ============================================================

// IF/ID pipeline register
reg [31:0] IFID_inst;
reg [31:0] IFID_pc;
reg [31:0] IFID_pc_plus4;
reg        IFID_predict_taken;
reg [31:0] IFID_predict_target;
reg        IFID_valid;

// ID/EX pipeline register
reg [31:0] IDEX_readData1, IDEX_readData2, IDEX_imm;
reg [31:0] IDEX_pc, IDEX_pc_plus4;
reg [4:0]  IDEX_rd, IDEX_rs1, IDEX_rs2;
reg [2:0]  IDEX_funct3;
reg        IDEX_funct7;
reg        IDEX_memRead, IDEX_memtoReg, IDEX_memWrite, IDEX_ALUSrc, IDEX_regWrite;
reg [1:0]  IDEX_ALUOp, IDEX_ALUSrcA;
reg        IDEX_jump_jal, IDEX_jump_jalr;
reg [31:0] IDEX_inst;   // trace only
reg        IDEX_valid;  // trace only

// EX/MEM pipeline register
reg [31:0] EXMEM_ALUResult, EXMEM_writeData;
reg [4:0]  EXMEM_rd;
reg [2:0]  EXMEM_funct3;
reg        EXMEM_memRead, EXMEM_memtoReg, EXMEM_memWrite, EXMEM_regWrite;
reg [31:0] EXMEM_pc, EXMEM_inst; // trace only
reg        EXMEM_valid;          // trace only

// MEM/WB pipeline register
reg [31:0] MEMWB_ALUResult, MEMWB_memReadData;
reg [4:0]  MEMWB_rd;
reg        MEMWB_memtoReg, MEMWB_regWrite;
reg [31:0] MEMWB_pc, MEMWB_inst, MEMWB_writeData; // trace only
reg [2:0]  MEMWB_funct3;                          // trace only
reg        MEMWB_memWrite, MEMWB_valid;           // trace only

// Forward-declared wire (driven from EX stage, used in ID stage forwarding)
wire [31:0] IDEX_ALUResult_pass;

// Hazard control
wire PCWrite, IF_ID_write, ID_EX_flush;
wire load_use_stall, load_branch_stall;

// ============================================================
// IF STAGE
// ============================================================

wire [31:0] pc_current, pc_plus4, inst_IF;
wire [31:0] pc_next;
wire        branch_taken;
wire [31:0] branch_target;

wire        predict_taken_IF;
wire [31:0] predict_target_IF;
wire        mispredict;
wire [31:0] corrected_pc;
wire        predictor_update_en;

assign pc_next = mispredict ? corrected_pc :
                  (predict_taken_IF ? predict_target_IF : pc_plus4);

PC #(.RESET_VECTOR(RESET_VECTOR)) pc_reg (
    .clk (clk),
    .rst (rst),
    .en  (PCWrite),
    .pc_i(pc_next),
    .pc_o(pc_current)
);

Adder pc_adder (
    .a  (pc_current),
    .b  (32'd4),
    .sum(pc_plus4)
);

// Synchronous IMEM: present the address the PC register will hold next cycle.
assign imem_addr = ~rst    ? RESET_VECTOR :
                   PCWrite ? pc_next      : pc_current;
assign inst_IF   = imem_rdata;

BranchPredictor2bit bpred (
    .clk           (clk),
    .rst           (rst),
    .pc_lookup     (pc_current),
    .predict_taken (predict_taken_IF),
    .predict_target(predict_target_IF),
    .update_en     (predictor_update_en),
    .update_pc     (IFID_pc),
    .actual_taken  (branch_taken),
    .actual_target (branch_target)
);

wire IF_ID_flush;

always @(posedge clk) begin
    if (~rst || IF_ID_flush) begin
        IFID_inst     <= 32'b0;
        IFID_pc       <= 32'b0;
        IFID_pc_plus4 <= 32'b0;
        IFID_predict_taken  <= 1'b0;
        IFID_predict_target <= 32'b0;
        IFID_valid    <= 1'b0;
    end else if (IF_ID_write) begin
        IFID_inst     <= inst_IF;
        IFID_pc       <= pc_current;
        IFID_pc_plus4 <= pc_plus4;
        IFID_predict_taken  <= predict_taken_IF;
        IFID_predict_target <= predict_target_IF;
        IFID_valid    <= 1'b1;
    end
end

// ============================================================
// ID STAGE
// ============================================================

wire        memRead_ID, memtoReg_ID, memWrite_ID, ALUSrc_ID, regWrite_ID;
wire        branch_ID, jump_jal_ID, jump_jalr_ID;
wire        useRs1_ID, useRs2_ID;
wire [1:0]  ALUOp_ID, ALUSrcA_ID;
wire [31:0] readData1_ID, readData2_ID, imm_ID;
wire [31:0] writeData_WB;

Control ctrl (
    .opcode    (IFID_inst[6:0]),
    .memRead   (memRead_ID),
    .memtoReg  (memtoReg_ID),
    .ALUOp     (ALUOp_ID),
    .memWrite  (memWrite_ID),
    .ALUSrc    (ALUSrc_ID),
    .regWrite  (regWrite_ID),
    .ALUSrcA   (ALUSrcA_ID),
    .useRs1    (useRs1_ID),
    .useRs2    (useRs2_ID),
    .branch    (branch_ID),
    .jal_sig   (jump_jal_ID),
    .jalr_sig  (jump_jalr_ID)
);

Register reg_file (
    .clk      (clk),
    .rst      (rst),
    .regWrite (MEMWB_regWrite),
    .readReg1 (IFID_inst[19:15]),
    .readReg2 (IFID_inst[24:20]),
    .writeReg (MEMWB_rd),
    .writeData(writeData_WB),
    .readData1(readData1_ID),
    .readData2(readData2_ID)
);

ImmGen immgen (
    .inst(IFID_inst),
    .imm (imm_ID)
);

// Branch/jalr operand forwarding into ID. A load producer is never forwarded
// from here: the hazard unit stalls until the load reaches WB, where the
// register-file write bypass supplies its data.
wire [31:0] branch_fwd_A, branch_fwd_B;

wire fwd_branch_A_EX  = (IDEX_regWrite  && (IDEX_rd  != 5'b0) && (IDEX_rd  == IFID_inst[19:15]));
wire fwd_branch_B_EX  = (IDEX_regWrite  && (IDEX_rd  != 5'b0) && (IDEX_rd  == IFID_inst[24:20]));
wire fwd_branch_A_MEM = (EXMEM_regWrite && (EXMEM_rd != 5'b0) && (EXMEM_rd == IFID_inst[19:15]) && !fwd_branch_A_EX);
wire fwd_branch_B_MEM = (EXMEM_regWrite && (EXMEM_rd != 5'b0) && (EXMEM_rd == IFID_inst[24:20]) && !fwd_branch_B_EX);

assign branch_fwd_A = fwd_branch_A_EX  ? IDEX_ALUResult_pass :
                      fwd_branch_A_MEM ? EXMEM_ALUResult      : readData1_ID;
assign branch_fwd_B = fwd_branch_B_EX  ? IDEX_ALUResult_pass :
                      fwd_branch_B_MEM ? EXMEM_ALUResult      : readData2_ID;

wire branch_eq  = (branch_fwd_A == branch_fwd_B);
wire branch_lt  = ($signed(branch_fwd_A) < $signed(branch_fwd_B));
wire branch_ltu = (branch_fwd_A < branch_fwd_B);

wire [2:0] funct3_ID = IFID_inst[14:12];

wire branch_cond =  (branch_ID) && (
                        (funct3_ID == 3'b000 &&  branch_eq)  ||
                        (funct3_ID == 3'b001 && !branch_eq)  ||
                        (funct3_ID == 3'b100 &&  branch_lt)  ||
                        (funct3_ID == 3'b101 && !branch_lt)  ||
                        (funct3_ID == 3'b110 &&  branch_ltu) ||
                        (funct3_ID == 3'b111 && !branch_ltu)
                    );

wire [31:0] jal_target  = IFID_pc + imm_ID;
wire [31:0] jalr_target = (branch_fwd_A + imm_ID) & ~32'b1;

assign branch_taken  = branch_cond || jump_jal_ID || jump_jalr_ID;
assign branch_target = jump_jalr_ID ? jalr_target :
                       jump_jal_ID  ? jal_target  :
                                      IFID_pc + imm_ID;

wire predict_correct = (branch_taken == IFID_predict_taken) &&
                        (!branch_taken || (branch_target == IFID_predict_target));

// While ID is stalled its operands may still be stale, so neither redirect
// the PC nor train the predictor until the instruction actually moves on.
wire stall_ID = ~IF_ID_write;
assign mispredict = IFID_valid && ~stall_ID && ~predict_correct;

assign corrected_pc = branch_taken ? branch_target : IFID_pc_plus4;

assign IF_ID_flush = mispredict;

assign predictor_update_en = (branch_ID || jump_jal_ID || jump_jalr_ID) && ~stall_ID;

always @(posedge clk) begin
    if (~rst || ID_EX_flush) begin
        IDEX_readData1 <= 32'b0; IDEX_readData2 <= 32'b0; IDEX_imm <= 32'b0;
        IDEX_pc        <= 32'b0; IDEX_pc_plus4  <= 32'b0;
        IDEX_rd  <= 5'b0; IDEX_rs1 <= 5'b0; IDEX_rs2 <= 5'b0;
        IDEX_funct3 <= 3'b0; IDEX_funct7 <= 1'b0;
        IDEX_memRead   <= 1'b0; IDEX_memtoReg  <= 1'b0; IDEX_memWrite <= 1'b0;
        IDEX_ALUSrc    <= 1'b0; IDEX_regWrite  <= 1'b0; IDEX_ALUOp <= 2'b0;
        IDEX_ALUSrcA   <= 2'b0;
        IDEX_jump_jal  <= 1'b0; IDEX_jump_jalr <= 1'b0;
        IDEX_inst      <= 32'b0; IDEX_valid    <= 1'b0;
    end else begin
        IDEX_readData1 <= readData1_ID; IDEX_readData2 <= readData2_ID;
        IDEX_imm       <= imm_ID;
        IDEX_pc        <= IFID_pc;
        IDEX_pc_plus4  <= IFID_pc_plus4;
        IDEX_rd        <= IFID_inst[11:7];
        IDEX_rs1       <= IFID_inst[19:15];
        IDEX_rs2       <= IFID_inst[24:20];
        IDEX_funct3    <= IFID_inst[14:12];
        IDEX_funct7    <= IFID_inst[30];
        IDEX_memRead   <= memRead_ID;  IDEX_memtoReg <= memtoReg_ID;
        IDEX_memWrite  <= memWrite_ID; IDEX_ALUSrc   <= ALUSrc_ID;
        IDEX_regWrite  <= regWrite_ID; IDEX_ALUOp    <= ALUOp_ID;
        IDEX_ALUSrcA   <= ALUSrcA_ID;
        IDEX_jump_jal  <= jump_jal_ID; IDEX_jump_jalr <= jump_jalr_ID;
        IDEX_inst      <= IFID_inst;   IDEX_valid     <= IFID_valid;
    end
end

// ============================================================
// EX STAGE
// ============================================================

wire [31:0] ALU_A_EX, ALU_B_EX, ALUResult_EX;
wire [3:0]  ALUCtl_EX;
wire        zero_EX, eff_sign_EX;
wire [1:0]  forwardA, forwardB;
wire [31:0] ALU_A_EX_reg, ALU_B_EX_reg;

Mux3to1 fwd_mux_A (
    .sel(forwardA),
    .in0(IDEX_readData1),
    .in1(writeData_WB),
    .in2(EXMEM_ALUResult),
    .out(ALU_A_EX_reg)
);

Mux3to1 fwd_mux_B_reg (
    .sel(forwardB),
    .in0(IDEX_readData2),
    .in1(writeData_WB),
    .in2(EXMEM_ALUResult),
    .out(ALU_B_EX_reg)
);

// Operand A: rs1 (default), pc (auipc) or zero (lui)
Mux3to1 alu_srcA_mux (
    .sel(IDEX_ALUSrcA),
    .in0(ALU_A_EX_reg),
    .in1(IDEX_pc),
    .in2(32'b0),
    .out(ALU_A_EX)
);

Mux2to1 alu_src_mux (
    .sel(IDEX_ALUSrc),
    .s0 (ALU_B_EX_reg),
    .s1 (IDEX_imm),
    .out(ALU_B_EX)
);

ALUCtrl alu_ctrl (
    .ALUOp (IDEX_ALUOp),
    .funct7(IDEX_funct7),
    .funct3(IDEX_funct3),
    .ALUCtl(ALUCtl_EX)
);

ALU alu (
    .ALUCtl (ALUCtl_EX),
    .A      (ALU_A_EX),
    .B      (ALU_B_EX),
    .ALUOut (ALUResult_EX),
    .zero   (zero_EX),
    .eff_sign(eff_sign_EX)
);

// jal/jalr write the link address; everything downstream (forwarding and
// writeback) sees it as the instruction's result.
wire [31:0] exResult_EX = (IDEX_jump_jal || IDEX_jump_jalr) ? IDEX_pc_plus4 : ALUResult_EX;

assign IDEX_ALUResult_pass = exResult_EX;

// Data memory request (synchronous: data returns in MEM)
StoreFormat store_fmt (
    .memWrite(IDEX_memWrite),
    .funct3  (IDEX_funct3),
    .addr_lo (ALUResult_EX[1:0]),
    .rs2_data(ALU_B_EX_reg),
    .wstrb   (dmem_we),
    .wdata   (dmem_wdata)
);

assign dmem_addr = ALUResult_EX;
assign dmem_re   = IDEX_memRead;

always @(posedge clk) begin
    if (~rst) begin
        EXMEM_ALUResult  <= 32'b0; EXMEM_writeData <= 32'b0;
        EXMEM_rd         <= 5'b0;  EXMEM_funct3    <= 3'b0;
        EXMEM_memRead    <= 1'b0;  EXMEM_memtoReg  <= 1'b0;
        EXMEM_memWrite   <= 1'b0;  EXMEM_regWrite  <= 1'b0;
        EXMEM_pc         <= 32'b0; EXMEM_inst      <= 32'b0;
        EXMEM_valid      <= 1'b0;
    end else begin
        EXMEM_ALUResult  <= exResult_EX;
        EXMEM_writeData  <= ALU_B_EX_reg;
        EXMEM_rd         <= IDEX_rd;
        EXMEM_funct3     <= IDEX_funct3;
        EXMEM_memRead    <= IDEX_memRead;  EXMEM_memtoReg <= IDEX_memtoReg;
        EXMEM_memWrite   <= IDEX_memWrite; EXMEM_regWrite <= IDEX_regWrite;
        EXMEM_pc         <= IDEX_pc;       EXMEM_inst     <= IDEX_inst;
        EXMEM_valid      <= IDEX_valid;
    end
end

// ============================================================
// MEM STAGE
// ============================================================

wire [31:0] memReadData_MEM;

LoadFormat load_fmt (
    .funct3   (EXMEM_funct3),
    .addr_lo  (EXMEM_ALUResult[1:0]),
    .rdata    (dmem_rdata),
    .load_data(memReadData_MEM)
);

always @(posedge clk) begin
    if (~rst) begin
        MEMWB_ALUResult  <= 32'b0;
        MEMWB_memReadData <= 32'b0;
        MEMWB_rd  <= 5'b0;
        MEMWB_memtoReg  <= 1'b0;
        MEMWB_regWrite  <= 1'b0;
        MEMWB_pc <= 32'b0; MEMWB_inst <= 32'b0; MEMWB_writeData <= 32'b0;
        MEMWB_funct3 <= 3'b0; MEMWB_memWrite <= 1'b0; MEMWB_valid <= 1'b0;
    end else begin
        MEMWB_ALUResult  <= EXMEM_ALUResult;
        MEMWB_memReadData <= memReadData_MEM;
        MEMWB_rd   <= EXMEM_rd;
        MEMWB_memtoReg  <= EXMEM_memtoReg; MEMWB_regWrite <= EXMEM_regWrite;
        MEMWB_pc <= EXMEM_pc; MEMWB_inst <= EXMEM_inst; MEMWB_writeData <= EXMEM_writeData;
        MEMWB_funct3 <= EXMEM_funct3; MEMWB_memWrite <= EXMEM_memWrite; MEMWB_valid <= EXMEM_valid;
    end
end

// ============================================================
// WB STAGE
// ============================================================

Mux2to1 wb_mux (
    .sel(MEMWB_memtoReg),
    .s0 (MEMWB_ALUResult),
    .s1 (MEMWB_memReadData),
    .out(writeData_WB)
);

// ============================================================
// HAZARD DETECTION UNIT
// ============================================================

HazardDetectionUnit hazard_unit (
    .IDEX_memRead     (IDEX_memRead),
    .IDEX_rd          (IDEX_rd),
    .EXMEM_memRead    (EXMEM_memRead),
    .EXMEM_rd         (EXMEM_rd),
    .IFID_rs1         (IFID_inst[19:15]),
    .IFID_rs2         (IFID_inst[24:20]),
    .IFID_useRs1      (useRs1_ID),
    .IFID_useRs2      (useRs2_ID),
    .IFID_resolvesInID(branch_ID || jump_jalr_ID),
    .PC_write         (PCWrite),
    .IFID_write       (IF_ID_write),
    .insert_nop       (ID_EX_flush),
    .load_use_stall   (load_use_stall),
    .load_branch_stall(load_branch_stall)
);

// ============================================================
// FORWARDING UNIT
// ============================================================

ForwardingUnit fwd_unit (
    .IDEX_rs1_addr  (IDEX_rs1),
    .IDEX_rs2_addr  (IDEX_rs2),
    .EXMEM_rd       (EXMEM_rd),
    .EXMEM_regWrite (EXMEM_regWrite),
    .MEMWB_rd       (MEMWB_rd),
    .MEMWB_regWrite (MEMWB_regWrite),
    .forwardA       (forwardA),
    .forwardB       (forwardB)
);

endmodule
