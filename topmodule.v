// TOP LEVEL
module PipelinedCPU (
    input clk,
    input rst,
    output [31:0] debug_pc,
    output [31:0] debug_inst,
    output [31:0] debug_alu_result,
    output [31:0] debug_reg_writedata,
    output        debug_regWrite
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

// ID/EX pipeline register
reg [31:0] IDEX_readData1, IDEX_readData2, IDEX_imm;
reg [31:0] IDEX_pc_plus4;
reg [4:0]  IDEX_rd, IDEX_rs1, IDEX_rs2;
reg [2:0]  IDEX_funct3;
reg        IDEX_funct7;
reg        IDEX_memRead, IDEX_memtoReg, IDEX_memWrite, IDEX_ALUSrc, IDEX_regWrite;
reg [1:0]  IDEX_ALUOp;
reg        IDEX_jump_jal, IDEX_jump_jalr;

// EX/MEM pipeline register
reg [31:0] EXMEM_ALUResult, EXMEM_writeData;
reg [31:0] EXMEM_pc_plus4;
reg [4:0]  EXMEM_rd;
reg        EXMEM_memRead, EXMEM_memtoReg, EXMEM_memWrite, EXMEM_regWrite;
reg        EXMEM_jump_jal, EXMEM_jump_jalr;

// MEM/WB pipeline register
reg [31:0] MEMWB_ALUResult, MEMWB_memReadData;
reg [31:0] MEMWB_pc_plus4;
reg [4:0]  MEMWB_rd;
reg        MEMWB_memtoReg, MEMWB_regWrite;
reg        MEMWB_jump_jal, MEMWB_jump_jalr;

// Forward-declared wire (driven from EX stage, used in ID stage forwarding)
wire [31:0] IDEX_ALUResult_pass;

// ============================================================
// IF STAGE
// ============================================================

wire [31:0] pc_current, pc_plus4, inst_IF;
wire        PCWrite;
wire [31:0] pc_next;
wire        branch_taken;
wire [31:0] branch_target;
wire [31:0] jump_target_ID;

wire        predict_taken_IF;
wire [31:0] predict_target_IF;
wire        mispredict;
wire [31:0] corrected_pc;

assign pc_next = mispredict ? corrected_pc :
                  (predict_taken_IF ? predict_target_IF : pc_plus4);

PC pc_reg (
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

InstructionMemory imem (
    .readAddr(pc_current),
    .inst    (inst_IF)
);

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
wire IF_ID_write;

always @(posedge clk) begin
    if (~rst || IF_ID_flush) begin
        IFID_inst     <= 32'b0;
        IFID_pc       <= 32'b0;
        IFID_pc_plus4 <= 32'b0;
        IFID_predict_taken  <= 1'b0;
        IFID_predict_target <= 32'b0;
    end else if (IF_ID_write) begin
        IFID_inst     <= inst_IF;
        IFID_pc       <= pc_current;
        IFID_pc_plus4 <= pc_plus4;
        IFID_predict_taken  <= predict_taken_IF;
        IFID_predict_target <= predict_target_IF;
    end
end

// ============================================================
// ID STAGE
// ============================================================

wire        memRead_ID, memtoReg_ID, memWrite_ID, ALUSrc_ID, regWrite_ID;
wire        branch_ID, jump_jal_ID, jump_jalr_ID;
wire [1:0]  ALUOp_ID;
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

wire [31:0] branch_fwd_A, branch_fwd_B;

wire fwd_branch_A_EX  = (IDEX_regWrite  && (IDEX_rd  != 5'b0) && (IDEX_rd  == IFID_inst[19:15]));
wire fwd_branch_B_EX  = (IDEX_regWrite  && (IDEX_rd  != 5'b0) && (IDEX_rd  == IFID_inst[24:20]));
wire fwd_branch_A_MEM = (EXMEM_regWrite && (EXMEM_rd != 5'b0) && (EXMEM_rd == IFID_inst[19:15]) && !fwd_branch_A_EX);
wire fwd_branch_B_MEM = (EXMEM_regWrite && (EXMEM_rd != 5'b0) && (EXMEM_rd == IFID_inst[24:20]) && !fwd_branch_B_EX);

assign branch_fwd_A = fwd_branch_A_EX  ? IDEX_ALUResult_pass :
                      fwd_branch_A_MEM ? EXMEM_ALUResult      : readData1_ID;
assign branch_fwd_B = fwd_branch_B_EX  ? IDEX_ALUResult_pass :
                      fwd_branch_B_MEM ? EXMEM_ALUResult      : readData2_ID;

wire [31:0] branch_diff = branch_fwd_A - branch_fwd_B;
wire branch_eq  = (branch_diff == 32'b0);
wire branch_lt  = ($signed(branch_fwd_A) < $signed(branch_fwd_B));

wire [2:0] funct3_ID = IFID_inst[14:12];

wire branch_cond =  (branch_ID) && (
                        (funct3_ID == 3'b000 &&  branch_eq) ||
                        (funct3_ID == 3'b001 && !branch_eq) ||
                        (funct3_ID == 3'b100 &&  branch_lt) ||
                        (funct3_ID == 3'b101 && !branch_lt)
                    );

wire [31:0] jal_target  = IFID_pc + imm_ID;
wire [31:0] jalr_target = (branch_fwd_A + imm_ID) & ~32'b1;

assign branch_taken  = branch_cond || jump_jal_ID || jump_jalr_ID;
assign branch_target = jump_jalr_ID ? jalr_target :
                       jump_jal_ID  ? jal_target  :
                                      IFID_pc + imm_ID;

wire predict_correct = (branch_taken == IFID_predict_taken) &&
                        (!branch_taken || (branch_target == IFID_predict_target));
assign mispredict = ~predict_correct;

assign corrected_pc = branch_taken ? branch_target : IFID_pc_plus4;

assign IF_ID_flush = mispredict;

wire predictor_update_en = branch_ID || jump_jal_ID || jump_jalr_ID;

wire ID_EX_flush;

always @(posedge clk) begin
    if (~rst || ID_EX_flush) begin
        IDEX_readData1 <= 32'b0; IDEX_readData2 <= 32'b0; IDEX_imm <= 32'b0;
        IDEX_pc_plus4  <= 32'b0;
        IDEX_rd  <= 5'b0; IDEX_rs1 <= 5'b0; IDEX_rs2 <= 5'b0;
        IDEX_funct3 <= 3'b0; IDEX_funct7 <= 1'b0;
        IDEX_memRead   <= 1'b0; IDEX_memtoReg  <= 1'b0; IDEX_memWrite <= 1'b0;
        IDEX_ALUSrc    <= 1'b0; IDEX_regWrite  <= 1'b0; IDEX_ALUOp <= 2'b0;
        IDEX_jump_jal  <= 1'b0; IDEX_jump_jalr <= 1'b0;
    end else begin
        IDEX_readData1 <= readData1_ID; IDEX_readData2 <= readData2_ID;
        IDEX_imm       <= imm_ID;
        IDEX_pc_plus4  <= IFID_pc_plus4;
        IDEX_rd        <= IFID_inst[11:7];
        IDEX_rs1       <= IFID_inst[19:15];
        IDEX_rs2       <= IFID_inst[24:20];
        IDEX_funct3    <= IFID_inst[14:12];
        IDEX_funct7    <= IFID_inst[30];
        IDEX_memRead   <= memRead_ID;  IDEX_memtoReg <= memtoReg_ID;
        IDEX_memWrite  <= memWrite_ID; IDEX_ALUSrc   <= ALUSrc_ID;
        IDEX_regWrite  <= regWrite_ID; IDEX_ALUOp    <= ALUOp_ID;
        IDEX_jump_jal  <= jump_jal_ID; IDEX_jump_jalr <= jump_jalr_ID;
    end
end

// ============================================================
// EX STAGE
// ============================================================

wire [31:0] ALU_A_EX, ALU_B_EX, ALUResult_EX;
wire [3:0]  ALUCtl_EX;
wire        zero_EX, eff_sign_EX;
wire [1:0]  forwardA, forwardB;
wire [31:0] ALU_B_EX_reg;

Mux3to1 fwd_mux_A (
    .sel(forwardA),
    .in0(IDEX_readData1),
    .in1(writeData_WB),
    .in2(EXMEM_ALUResult),
    .out(ALU_A_EX)
);

Mux3to1 fwd_mux_B_reg (
    .sel(forwardB),
    .in0(IDEX_readData2),
    .in1(writeData_WB),
    .in2(EXMEM_ALUResult),
    .out(ALU_B_EX_reg)
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

assign IDEX_ALUResult_pass = ALUResult_EX;

always @(posedge clk) begin
    if (~rst) begin
        EXMEM_ALUResult  <= 32'b0; EXMEM_writeData <= 32'b0;
        EXMEM_pc_plus4   <= 32'b0; EXMEM_rd        <= 5'b0;
        EXMEM_memRead    <= 1'b0;  EXMEM_memtoReg  <= 1'b0;
        EXMEM_memWrite   <= 1'b0;  EXMEM_regWrite  <= 1'b0;
        EXMEM_jump_jal   <= 1'b0;  EXMEM_jump_jalr <= 1'b0;
    end else begin
        EXMEM_ALUResult  <= ALUResult_EX;
        EXMEM_writeData  <= ALU_B_EX_reg;
        EXMEM_pc_plus4   <= IDEX_pc_plus4;
        EXMEM_rd         <= IDEX_rd;
        EXMEM_memRead    <= IDEX_memRead;  EXMEM_memtoReg <= IDEX_memtoReg;
        EXMEM_memWrite   <= IDEX_memWrite; EXMEM_regWrite <= IDEX_regWrite;
        EXMEM_jump_jal   <= IDEX_jump_jal; EXMEM_jump_jalr <= IDEX_jump_jalr;
    end
end

assign debug_pc           = pc_current;
assign debug_inst         = IFID_inst;
assign debug_alu_result   = ALUResult_EX;
assign debug_reg_writedata = writeData_WB;
assign debug_regWrite     = MEMWB_regWrite;

// ============================================================
// MEM STAGE
// ============================================================

wire [31:0] memReadData_MEM;

DataMemory dmem (
    .rst      (rst),
    .clk      (clk),
    .memWrite (EXMEM_memWrite),
    .memRead  (EXMEM_memRead),
    .address  (EXMEM_ALUResult),
    .writeData(EXMEM_writeData),
    .readData (memReadData_MEM)
);

always @(posedge clk) begin
    if (~rst) begin
        MEMWB_ALUResult  <= 32'b0;
        MEMWB_memReadData <= 32'b0;
        MEMWB_pc_plus4    <= 32'b0;
        MEMWB_rd  <= 5'b0;
        MEMWB_memtoReg  <= 1'b0;
        MEMWB_regWrite  <= 1'b0;
        MEMWB_jump_jal  <= 1'b0;
        MEMWB_jump_jalr <= 1'b0;
    end else begin
        MEMWB_ALUResult  <= EXMEM_ALUResult;
        MEMWB_memReadData <= memReadData_MEM;
        MEMWB_pc_plus4    <= EXMEM_pc_plus4;
        MEMWB_rd   <= EXMEM_rd;
        MEMWB_memtoReg  <= EXMEM_memtoReg; MEMWB_regWrite <= EXMEM_regWrite;
        MEMWB_jump_jal  <= EXMEM_jump_jal; MEMWB_jump_jalr <= EXMEM_jump_jalr;
    end
end

// ============================================================
// WB STAGE
// ============================================================

wire [31:0] wb_alu_or_mem;

Mux2to1 wb_mux (
    .sel(MEMWB_memtoReg),
    .s0 (MEMWB_ALUResult),
    .s1 (MEMWB_memReadData),
    .out(wb_alu_or_mem)
);

assign writeData_WB = (MEMWB_jump_jal || MEMWB_jump_jalr) ? MEMWB_pc_plus4 : wb_alu_or_mem;

// ============================================================
// HAZARD DETECTION UNIT
// ============================================================

HazardDetectionUnit hazard_unit (
    .IDEX_memRead  (IDEX_memRead),
    .IDEX_rd       (IDEX_rd),
    .IFID_rs1      (IFID_inst[19:15]),
    .IFID_rs2      (IFID_inst[24:20]),
    .mispredict    (mispredict),
    .IDEX_jalr_sig (jump_jalr_ID),
    .jal_sig       (jump_jal_ID),
    .PC_write      (PCWrite),
    .IFID_write    (IF_ID_write),
    .insert_nop    (ID_EX_flush),
    .IF_flush      ()
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