module PipelinedCPU (
    input clk,
    input rst
);


// IF STAGE

wire [31:0] pc_current, pc_plus4, inst_IF;
wire        PCWrite;          // from hazard unit: stall PC when 0
wire [31:0] pc_next;          // final next-PC (branch/jump or pc+4)
wire        branch_taken;     // from ID stage branch logic
wire [31:0] branch_target;    // from ID stage branch logic
wire [31:0] jump_target_ID;   // JAL/JALR target

// --- 2-bit saturating counter branch predictor (BTB-style, direct mapped) ---
wire        predict_taken_IF;   // speculative prediction for pc_current (this fetch)
wire [31:0] predict_target_IF;  // predicted target if predict_taken_IF
wire        mispredict;         // resolved in ID: prediction for IFID instr was wrong
wire [31:0] corrected_pc;       // recovery PC to use on misprediction

// pc_next mux: on misprediction, use the resolved (correct) address.
// Otherwise, speculatively follow the predictor: predicted target if it says
// taken, else pc+4. This lets correctly-predicted taken branches run with
// zero bubbles, unlike the old "always predict not-taken" scheme.
assign pc_next = mispredict ? corrected_pc :
                  (predict_taken_IF ? predict_target_IF : pc_plus4);

PC pc_reg (
    .clk    (clk),
    .rst    (rst),
    .PCWrite(PCWrite),
    .pc_i   (pc_next),
    .pc_o   (pc_current)
);

AdderPC_4 pc_adder (
    .a  (pc_current),
    .b  (32'd4),
    .sum(pc_plus4)
);

InstructionMemory imem (
    .readAddr(pc_current),
    .inst    (inst_IF)
);

// Predictor lookup uses pc_current (this cycle's fetch address, combinational).
// Predictor update/training uses the branch/jump currently resolving in ID
// (IFID_pc / branch_taken / branch_target, and predictor_update_en, all wired
// below in the ID stage section).
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

// IF/ID pipeline register
// Flushed (NOP inserted) when branch_taken or hazard_stall flushes IF/ID
wire IF_ID_flush;   // flush this register (branch taken)
wire IF_ID_write;   // write enable (stall when 0)

reg [31:0] IFID_inst;
reg [31:0] IFID_pc;          // PC of instruction in ID (needed for branch target/JAL)
reg [31:0] IFID_pc_plus4;    // pc+4 in ID (link address for JAL/JALR)
reg        IFID_predict_taken;   // prediction made when this instruction was fetched
reg [31:0] IFID_predict_target;  // predicted target at that time

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


// ID STAGE

wire        memRead_ID, memtoReg_ID, memWrite_ID, ALUSrc_ID, regWrite_ID;
wire        branch_ID, jump_jal_ID, jump_jalr_ID;
wire [1:0]  ALUOp_ID;
wire [31:0] readData1_ID, readData2_ID, imm_ID;
wire [31:0] writeData_WB;   // from WB stage (write-back to reg file)

Control ctrl (
    .opcode    (IFID_inst[6:0]),
    .memRead   (memRead_ID),
    .memtoReg  (memtoReg_ID),
    .ALUOp     (ALUOp_ID),
    .memWrite  (memWrite_ID),
    .ALUSrc    (ALUSrc_ID),
    .regWrite  (regWrite_ID),
    .branch    (branch_ID),
    .jump_jal  (jump_jal_ID),
    .jump_jalr (jump_jalr_ID)
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

// Branch resolution in ID 
// Forward from EX (IDEX) or MEM (EXMEM) for branch comparands if needed.


// Forwarding muxes for branch operands (only ALU-result forwarding; load
// forwarding to branch needs an extra stall - handled by hazard unit)
wire [31:0] branch_fwd_A, branch_fwd_B;

// Forward EX result if the instruction in EX writes to rs1/rs2 of the branch
wire fwd_branch_A_EX  = (IDEX_regWrite  && (IDEX_rd  != 5'b0) && (IDEX_rd  == IFID_inst[19:15]));
wire fwd_branch_B_EX  = (IDEX_regWrite  && (IDEX_rd  != 5'b0) && (IDEX_rd  == IFID_inst[24:20]));
// Forward MEM result
wire fwd_branch_A_MEM = (EXMEM_regWrite && (EXMEM_rd != 5'b0) && (EXMEM_rd == IFID_inst[19:15]) && !fwd_branch_A_EX);
wire fwd_branch_B_MEM = (EXMEM_regWrite && (EXMEM_rd != 5'b0) && (EXMEM_rd == IFID_inst[24:20]) && !fwd_branch_B_EX);

assign branch_fwd_A = fwd_branch_A_EX  ? IDEX_ALUResult_pass :
                      fwd_branch_A_MEM ? EXMEM_ALUResult      : readData1_ID;
assign branch_fwd_B = fwd_branch_B_EX  ? IDEX_ALUResult_pass :
                      fwd_branch_B_MEM ? EXMEM_ALUResult      : readData2_ID;

// Comparison for beq/bne/blt/bge
wire [31:0] branch_diff = branch_fwd_A - branch_fwd_B;
wire branch_eq  = (branch_diff == 32'b0);
wire branch_lt  = ($signed(branch_fwd_A) < $signed(branch_fwd_B));

wire [2:0] funct3_ID = IFID_inst[14:12];

wire branch_cond =  (branch_ID) && (
                        (funct3_ID == 3'b000 &&  branch_eq) ||   // beq
                        (funct3_ID == 3'b001 && !branch_eq) ||   // bne
                        (funct3_ID == 3'b100 &&  branch_lt) ||   // blt
                        (funct3_ID == 3'b101 && !branch_lt)      // bge
                    );

// JAL target = PC + imm
// JALR target = (rs1 + imm) & ~1
wire [31:0] jal_target  = IFID_pc + imm_ID;
wire [31:0] jalr_target = (branch_fwd_A + imm_ID) & ~32'b1;

assign branch_taken  = branch_cond || jump_jal_ID || jump_jalr_ID;
assign branch_target = jump_jalr_ID ? jalr_target :
                       jump_jal_ID  ? jal_target  :
                                      IFID_pc + imm_ID; // branch PC-relative

// Misprediction check: compare the actual resolved outcome (branch_taken /
// branch_target, for the instruction currently in ID) against the prediction
// that was made back when it was fetched (IFID_predict_taken/target).
// - If actual and predicted directions differ -> misprediction.
// - If both say "taken" but the resolved target differs from the predicted
//   target (e.g. stale/compulsory-miss BTB entry) -> also a misprediction.
wire predict_correct = (branch_taken == IFID_predict_taken) &&
                        (!branch_taken || (branch_target == IFID_predict_target));
assign mispredict = ~predict_correct;

// Recovery PC on misprediction: the resolved branch target, or fall-through
// (pc+4 of the mispredicted instruction) if the predictor wrongly said "taken"
assign corrected_pc = branch_taken ? branch_target : IFID_pc_plus4;

// Flush IF/ID only on misprediction now (discard the wrong-path instruction).
// Correctly predicted taken branches no longer cost a bubble.
assign IF_ID_flush = mispredict;

// Train the predictor whenever a branch/jump instruction resolves in ID
wire predictor_update_en = branch_ID || jump_jal_ID || jump_jalr_ID;

// IDEX pass-through of ALU result (needed for branch forwarding from EX stage)
// This is just a wire to the EX/MEM register's ALU result — declared later
// We need a forward declaration wire here:
wire [31:0] IDEX_ALUResult_pass;  // will be driven from EX stage wire

// ID/EX pipeline register
// Hazard unit stalls ID/EX (insert NOP) when load-use detected
wire ID_EX_flush;

reg [31:0] IDEX_readData1, IDEX_readData2, IDEX_imm;
reg [31:0] IDEX_pc_plus4;   // for JAL/JALR link-address write
reg [4:0]  IDEX_rd, IDEX_rs1, IDEX_rs2;
reg [2:0]  IDEX_funct3;
reg        IDEX_funct7;
reg        IDEX_memRead, IDEX_memtoReg, IDEX_memWrite, IDEX_ALUSrc, IDEX_regWrite;
reg [1:0]  IDEX_ALUOp;
reg        IDEX_jump_jal, IDEX_jump_jalr;  // for link address writeback in WB

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


// EX STAGE


wire [31:0] ALU_A_EX, ALU_B_EX, ALUResult_EX;
wire [3:0]  ALUCtl_EX;
wire        zero_EX, eff_sign_EX;
wire [1:0]  forwardA, forwardB;   // from forwarding unit

// Forwarding muxes for ALU operands
Mux3to1 fwd_mux_A (
    .sel(forwardA),
    .s0 (IDEX_readData1),   // from register file (no hazard)
    .s1 (writeData_WB),     // forward from WB  (MEM/WB ALU or mem result)
    .s2 (EXMEM_ALUResult),  // forward from MEM (EX/MEM ALU result)
    .out(ALU_A_EX)
);

Mux3to1 fwd_mux_B_reg (
    .sel(forwardB),
    .s0 (IDEX_readData2),
    .s1 (writeData_WB),
    .s2 (EXMEM_ALUResult),
    .out(ALU_B_EX_reg)      // forwarded rs2 value
);

wire [31:0] ALU_B_EX_reg;

// ALUSrc mux: choose between forwarded rs2 or immediate
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

// EX/MEM pipeline register
reg [31:0] EXMEM_ALUResult, EXMEM_writeData;
reg [31:0] EXMEM_pc_plus4;
reg [4:0]  EXMEM_rd;
reg        EXMEM_memRead, EXMEM_memtoReg, EXMEM_memWrite, EXMEM_regWrite;
reg        EXMEM_jump_jal, EXMEM_jump_jalr;

always @(posedge clk) begin
    if (~rst) begin
        EXMEM_ALUResult  <= 32'b0; EXMEM_writeData <= 32'b0;
        EXMEM_pc_plus4   <= 32'b0; EXMEM_rd        <= 5'b0;
        EXMEM_memRead    <= 1'b0;  EXMEM_memtoReg  <= 1'b0;
        EXMEM_memWrite   <= 1'b0;  EXMEM_regWrite  <= 1'b0;
        EXMEM_jump_jal   <= 1'b0;  EXMEM_jump_jalr <= 1'b0;
    end else begin
        EXMEM_ALUResult  <= ALUResult_EX;
        EXMEM_writeData  <= ALU_B_EX_reg;   // forwarded rs2 for SW
        EXMEM_pc_plus4   <= IDEX_pc_plus4;
        EXMEM_rd         <= IDEX_rd;
        EXMEM_memRead    <= IDEX_memRead;  EXMEM_memtoReg <= IDEX_memtoReg;
        EXMEM_memWrite   <= IDEX_memWrite; EXMEM_regWrite <= IDEX_regWrite;
        EXMEM_jump_jal   <= IDEX_jump_jal; EXMEM_jump_jalr <= IDEX_jump_jalr;
    end
end

// MEM STAGE


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

// MEM/WB pipeline register
reg [31:0] MEMWB_ALUResult, MEMWB_memReadData;
reg [31:0] MEMWB_pc_plus4;
reg [4:0]  MEMWB_rd;
reg        MEMWB_memtoReg, MEMWB_regWrite;
reg        MEMWB_jump_jal, MEMWB_jump_jalr;

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


// WB STAGE


// writeData_WB: ALU result, memory read data, or pc+4 (link address for JAL/JALR)
wire [31:0] wb_alu_or_mem;

Mux2to1 wb_mux (
    .sel(MEMWB_memtoReg),
    .s0 (MEMWB_ALUResult),
    .s1 (MEMWB_memReadData),
    .out(wb_alu_or_mem)
);

// For JAL/JALR: write pc+4 (return address) into rd
assign writeData_WB = (MEMWB_jump_jal || MEMWB_jump_jalr) ? MEMWB_pc_plus4 : wb_alu_or_mem;


// HAZARD DETECTION UNIT

HazardDetection hazard_unit (
    .IDEX_memRead   (IDEX_memRead),
    .IDEX_rd        (IDEX_rd),
    .IFID_rs1       (IFID_inst[19:15]),
    .IFID_rs2       (IFID_inst[24:20]),
    .branch_taken   (branch_taken),
    .PCWrite        (PCWrite),
    .IF_ID_write    (IF_ID_write),
    .ID_EX_flush    (ID_EX_flush)
);


// FORWARDING UNIT

ForwardingUnit fwd_unit (
    .IDEX_rs1       (IDEX_rs1),
    .IDEX_rs2       (IDEX_rs2),
    .EXMEM_rd       (EXMEM_rd),
    .EXMEM_regWrite (EXMEM_regWrite),
    .MEMWB_rd       (MEMWB_rd),
    .MEMWB_regWrite (MEMWB_regWrite),
    .forwardA       (forwardA),
    .forwardB       (forwardB)
);

endmodule
