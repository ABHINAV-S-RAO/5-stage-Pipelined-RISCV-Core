module topmodule (
    input clk,
    input start
    
);

// When input start is zero, cpu should reset
// When input start is high, cpu start running

wire [31:0] pc_current; // Current PC output
wire [31:0] pc_next;    // Next PC input
// In SingleCycleCPU, replace the PC instantiation wire with enable:
PC m_PC(
    .clk(clk),
    .rst (start),
    .en (PC_write),   
    .pc_i (pc_next),
    .pc_o (pc_current)
);

wire [31:0] pc_plus4;

Adder m_Adder_1(
    .a(pc_current),
    .b(32'd4),
    .sum(pc_plus4)
);

// output instruction wire
wire [31:0] instruction;
InstructionMemory m_InstMem(
    .readAddr(pc_current),   // address = current PC
    .inst(instruction)       // output instruction
);

// control unit wires
wire branch;
wire memRead;
wire memtoReg;
wire [1:0] ALUOp;
wire memWrite;
wire ALUSrc;
wire regWrite;
wire [2:0] funct3;
wire funct7_bit;
wire EX_flush;

wire jal_sig,jalr_sig;
// register file outputs
wire [31:0] readData1;
wire [31:0] readData2;
wire [31:0] writeData;

//IF/ID pipeline register
reg [31:0] IFID_inst, IFID_pc, IFID_pc4;

//ID/EX pipeline register
reg [31:0] IDEX_pc, IDEX_pc4;
reg [31:0] IDEX_rs1, IDEX_rs2, IDEX_imm, IDEX_imm_shifted;
reg [4:0]  IDEX_rs1_addr, IDEX_rs2_addr, IDEX_rd;
reg [2:0]  IDEX_funct3;
reg  IDEX_funct7;
reg  IDEX_branch, IDEX_memRead, IDEX_memtoReg;
reg [1:0]  IDEX_ALUOp;
reg  IDEX_memWrite, IDEX_ALUSrc, IDEX_regWrite;
reg  IDEX_jal_sig, IDEX_jalr_sig;
reg IDEX_branch_taken;
reg [31:0] IDEX_branch_target;

//EX/MEM pipeline register
reg [31:0] EXMEM_alu_result, EXMEM_rs2;
reg [31:0] EXMEM_branch_target, EXMEM_jalr_target, EXMEM_pc4;
reg [4:0]  EXMEM_rd;
reg  EXMEM_zero, EXMEM_eff_sign, EXMEM_branch_taken;
reg  EXMEM_memRead, EXMEM_memWrite, EXMEM_regWrite;
reg  EXMEM_memtoReg, EXMEM_jal_sig, EXMEM_jalr_sig;

//MEM/WB pipeline register
reg [31:0] MEMWB_mem_data, MEMWB_alu_result, MEMWB_pc4;
reg [4:0]  MEMWB_rd;
reg  MEMWB_regWrite, MEMWB_memtoReg;
reg   MEMWB_jal_sig, MEMWB_jalr_sig;

//IF/ID latch
always@(posedge clk) begin
if(~start) begin
    IFID_inst <= 32'b0;
    IFID_pc <= 32'b0;
    IFID_pc4  <= 32'b0;
end else if(IF_flush) begin
    IFID_inst <= 32'b0;// NOP the instruction
    // We DO NOT zero pc or pc4 — jal still needs its correct pc4 for writeback
end else if(IFID_write) begin
    IFID_inst <= instruction;
    IFID_pc <= pc_current;
    IFID_pc4 <= pc_plus4;
end
//if IFID_write=0, regs hold their previous value (stall)
end

//ID/EX latch
always @(posedge clk) begin
    if (~start || insert_nop) begin
        IDEX_pc   <= 32'b0;
        IDEX_pc4  <= 32'b0;
        IDEX_rs1  <= 32'b0;
        IDEX_rs2   <= 32'b0;
        IDEX_imm   <= 32'b0;
        IDEX_imm_shifted <= 32'b0;
        IDEX_rs1_addr  <= 5'b0;
        IDEX_rs2_addr  <= 5'b0;
        IDEX_rd   <= 5'b0;
        IDEX_funct3  <= 3'b0;
        IDEX_funct7  <= 1'b0;
        IDEX_branch  <= 1'b0;
        IDEX_memRead  <= 1'b0;
        IDEX_memtoReg  <= 1'b0;
        IDEX_ALUOp  <= 2'b0;
        IDEX_memWrite <= 1'b0;
        IDEX_ALUSrc  <= 1'b0;
        IDEX_regWrite <= 1'b0;
        IDEX_jal_sig  <= 1'b0;
        IDEX_jalr_sig  <= 1'b0;
        IDEX_branch_taken <= 1'b0;
    end else begin
        IDEX_pc  <= IFID_pc;
        IDEX_pc4 <= IFID_pc4;
        IDEX_rs1 <= readData1;
        IDEX_rs2 <= readData2;
        IDEX_imm  <= imm;
        IDEX_imm_shifted <= imm_shifted;
        IDEX_rs1_addr  <= IFID_inst[19:15];
        IDEX_rs2_addr <= IFID_inst[24:20];
        IDEX_rd  <= IFID_inst[11:7];
        IDEX_funct3  <= funct3;
        IDEX_funct7  <= funct7_bit;
        IDEX_branch <= branch;
        IDEX_memRead  <= memRead;
        IDEX_memtoReg  <= memtoReg;
        IDEX_ALUOp  <= ALUOp;
        IDEX_memWrite  <= memWrite;
        IDEX_ALUSrc  <= ALUSrc;
        IDEX_regWrite  <= regWrite;
        IDEX_jal_sig  <= jal_sig;
        IDEX_jalr_sig  <= jalr_sig;
        IDEX_branch_taken <= branch_taken;
        IDEX_branch_target <= branch_jal_target;
    end
end

//EX/MEM latch
always @(posedge clk) begin
    if (~start) begin
        EXMEM_alu_result <= 32'b0;
        EXMEM_zero <= 1'b0;
        EXMEM_eff_sign <= 1'b0;
        EXMEM_rs2 <= 32'b0;
        EXMEM_rd <= 5'b0;
        EXMEM_pc4 <= 32'b0;
        EXMEM_branch_target <= 32'b0;
        EXMEM_jalr_target <= 32'b0;
        EXMEM_branch_taken <= 1'b0;
        EXMEM_memRead <= 1'b0;
        EXMEM_memWrite <= 1'b0;
        EXMEM_regWrite <= 1'b0;
        EXMEM_memtoReg <= 1'b0;
        EXMEM_jal_sig  <= 1'b0;
        EXMEM_jalr_sig  <= 1'b0;
    end else begin
        EXMEM_alu_result  <= ALUOut;
        EXMEM_zero  <= zero;
        EXMEM_eff_sign <= eff_sign;
        EXMEM_rs2 <= alu_B_forwarded; //was IDEX_rs2
        EXMEM_rd <= IDEX_rd;
        EXMEM_pc4   <= IDEX_pc4;
        EXMEM_branch_target <= IDEX_branch_target;
        EXMEM_jalr_target <= jalr_target;
        EXMEM_branch_taken  <= branch_taken;
        EXMEM_memRead <= IDEX_memRead;
        EXMEM_memWrite  <= IDEX_memWrite;
        EXMEM_regWrite  <= IDEX_regWrite;
        EXMEM_memtoReg  <= IDEX_memtoReg;
        EXMEM_jal_sig   <= IDEX_jal_sig;
        EXMEM_jalr_sig  <= IDEX_jalr_sig;
    end
end

//MEM/WB latch
always @(posedge clk) begin
    if (~start) begin
        MEMWB_mem_data  <= 32'b0;
        MEMWB_alu_result <= 32'b0;
        MEMWB_rd  <= 5'b0;
        MEMWB_pc4  <= 32'b0;
        MEMWB_regWrite <= 1'b0;
        MEMWB_memtoReg <= 1'b0;
        MEMWB_jal_sig  <= 1'b0;
        MEMWB_jalr_sig  <= 1'b0;
    end else begin
        MEMWB_mem_data  <= memReadData;
        MEMWB_alu_result <= EXMEM_alu_result;
        MEMWB_rd <= EXMEM_rd;
        MEMWB_pc4  <= EXMEM_pc4;
        MEMWB_regWrite  <= EXMEM_regWrite;
        MEMWB_memtoReg  <= EXMEM_memtoReg;
        MEMWB_jal_sig   <= EXMEM_jal_sig;
        MEMWB_jalr_sig  <= EXMEM_jalr_sig;
    end
end


Control m_Control(
    .opcode(IFID_inst[6:0]), // opcode field
    .branch(branch),
    .memRead(memRead),
    .memtoReg(memtoReg),
    .ALUOp(ALUOp),
    .memWrite(memWrite),
    .ALUSrc(ALUSrc),
    .regWrite(regWrite),
    .jal_sig(jal_sig),
    .jalr_sig(jalr_sig)
);




Register m_Register(
    .clk(clk),
    .rst(start),
    .regWrite(MEMWB_regWrite),
    .readReg1(IFID_inst[19:15]),
    .readReg2(IFID_inst[24:20]),
    .writeReg(MEMWB_rd),
    .writeData(writeData),
    .readData1(readData1),
    .readData2(readData2)
);


wire [31:0] imm; // output from immgen unit
ImmGen m_ImmGen(
    .inst(IFID_inst),
    .imm(imm)
);

wire [31:0] imm_shifted; //for branch instructions the immidiate will be shifted left by a bit
ShiftLeftOne m_ShiftLeftOne(
    .i(imm),
    .o(imm_shifted)
);


wire [31:0] branch_jal_target; // this will go to a mux which decides what next PC is.
// branch/jal target adder
Adder m_Adder_2(
    .a(IFID_pc),
    .b(imm),
    .sum(branch_jal_target)
);

wire [31:0] jalr_target_raw;
Adder jalr_adder(.a(alu_A), .b(IDEX_imm), .sum(jalr_target_raw));
wire [31:0] jalr_target = jalr_target_raw & ~32'b1;

wire branch_taken;
//Forward correct rs1/rs2 values for branch comparison in ID stage
reg [31:0] branch_rs1, branch_rs2;

always @(*) begin
    // Forward rs1
    if (IDEX_regWrite && IDEX_rd != 0 && IDEX_rd == IFID_inst[19:15])
        branch_rs1 = (IDEX_jal_sig | IDEX_jalr_sig) ? IDEX_pc4 : ALUOut;
    else if (EXMEM_regWrite && EXMEM_rd != 0 && EXMEM_rd == IFID_inst[19:15])
        branch_rs1 = EXMEM_alu_result;
    else if (MEMWB_regWrite && MEMWB_rd != 0 && MEMWB_rd == IFID_inst[19:15])
        branch_rs1 = writeData;
    else
        branch_rs1 = readData1;

    // Forward rs2
    if (IDEX_regWrite && IDEX_rd != 0 && IDEX_rd == IFID_inst[24:20])
        branch_rs2 = (IDEX_jal_sig | IDEX_jalr_sig) ? IDEX_pc4 : ALUOut;
    else if (EXMEM_regWrite && EXMEM_rd != 0 && EXMEM_rd == IFID_inst[24:20])
        branch_rs2 = EXMEM_alu_result;
    else if (MEMWB_regWrite && MEMWB_rd != 0 && MEMWB_rd == IFID_inst[24:20])
        branch_rs2 = writeData;
    else
        branch_rs2 = readData2;
end
branch_control bcntrl(
    .branch(branch),
    .funct3(funct3),
    .rs1(branch_rs1),   //was readData1
    .rs2(branch_rs2),   //was readData2
    .branch_taken(branch_taken)
);

// w1: branch target (ID stage)
wire [31:0] w1, w2_pc;
// JAL joins branch in ID-stage redirect
wire id_redirect = branch_taken | jal_sig;
// First pick between PC+4 and branch target
Mux2to1 m_Mux_PC0(
    .sel(id_redirect),
    .s0(pc_plus4),
    .s1(branch_jal_target),
    .out(w1)
);

// Then override with jal/jalr if needed (EXMEM stage)
wire mux1cntrl;
assign mux1cntrl = EXMEM_jal_sig | EXMEM_jalr_sig;
Mux2to1 m_Mux_PC1(
    .sel(IDEX_jalr_sig),
    .s0(w1),
    .s1(jalr_target),
    .out(pc_next)
);

reg [31:0] alu_A;  // final A operand into ALU after forwarding
reg [31:0] alu_B_forwarded;  // final B operand after forwarding, before ALUSrc mux

always @(*) begin
    case(forwardA)
        2'b00: alu_A = IDEX_rs1;
        2'b01: alu_A = writeData;
        2'b10: alu_A = (EXMEM_jal_sig | EXMEM_jalr_sig) ? EXMEM_pc4 : EXMEM_alu_result;
        default: alu_A = IDEX_rs1;
    endcase
end

always @(*) begin
    case(forwardB)
        2'b00: alu_B_forwarded = IDEX_rs2;
        2'b01: alu_B_forwarded = writeData;
        2'b10: alu_B_forwarded = (EXMEM_jal_sig | EXMEM_jalr_sig) ? EXMEM_pc4 : EXMEM_alu_result;
        default: alu_B_forwarded = IDEX_rs2;
    endcase
end
//This mux decides B input to the ALU
wire [31:0] alu_B; //goes as input to the ALU
Mux2to1 m_Mux_ALU(
    .sel(IDEX_ALUSrc),
    .s0(alu_B_forwarded),//was IDEX_rs2
    .s1(IDEX_imm),
    .out(alu_B)
);

wire [3:0] ALUCtl;//output of ALU Control unit


assign funct3 = IFID_inst[14:12];
assign funct7_bit = IFID_inst[30];

ALUCtrl m_ALUCtrl(
    .ALUOp(IDEX_ALUOp),
    .funct7(IDEX_funct7),
    .funct3(IDEX_funct3),
    .ALUCtl(ALUCtl)
);

wire [31:0] ALUOut; //output of the ALU
wire zero,eff_sign;
ALU m_ALU(
    .ALUCtl(ALUCtl),
    .A(alu_A), //was IDEX_rs1
    .B(alu_B),
    .ALUOut(ALUOut),
    .zero(zero),
    .eff_sign(eff_sign)
);



wire [31:0] memReadData; //data read out from the data memory when memRead is asserted

DataMemory m_DataMemory(
    .rst(start),
    .clk(clk),
    .memWrite(EXMEM_memWrite),
    .memRead(EXMEM_memRead),
    .address(EXMEM_alu_result),
    .writeData(EXMEM_rs2),  //rs2 value for sw
    .readData(memReadData)   //data read out for lw
);

wire [31:0] w2; //intermediary for writeback mux
Mux2to1 m_Mux_WriteData0(
    .sel(MEMWB_memtoReg),
    .s0(MEMWB_alu_result),
    .s1(MEMWB_mem_data),  //Data memory read output (for lw)
    .out(w2)
);

//additional mux for PC + 4 write backs
Mux2to1 m_Mux_WriteData1(
    .sel(MEMWB_jal_sig | MEMWB_jalr_sig),  //will write back PC + 4 only for jal/jalr
    .s0(w2),        //ALU/Data Memory data
    .s1(MEMWB_pc4),// PC + 4
    .out(writeData)
);

wire [1:0] forwardA, forwardB;

ForwardingUnit m_ForwardingUnit(
    .IDEX_rs1_addr(IDEX_rs1_addr),
    .IDEX_rs2_addr(IDEX_rs2_addr),
    .EXMEM_rd(EXMEM_rd),
    .MEMWB_rd(MEMWB_rd),
    .EXMEM_regWrite(EXMEM_regWrite),
    .MEMWB_regWrite(MEMWB_regWrite),
    .forwardA(forwardA),
    .forwardB(forwardB)
);

wire PC_write, IFID_write, insert_nop, IF_flush;
HazardDetectionUnit m_HazardUnit (
    .IDEX_memRead (IDEX_memRead),
    .IDEX_rd (IDEX_rd),
    .IFID_rs1(IFID_inst[19:15]),
    .IFID_rs2 (IFID_inst[24:20]),
    .branch_taken(branch_taken),
    .jal_sig (jal_sig),
    .IDEX_jalr_sig (IDEX_jalr_sig), 
    .PC_write(PC_write),
    .IFID_write (IFID_write),
    .insert_nop (insert_nop),
    .IF_flush (IF_flush),
    .EX_flush(EX_flush)
);
endmodule
module topmodule (
    input clk,
    input start
    
);

// When input start is zero, cpu should reset
// When input start is high, cpu start running

wire [31:0] pc_current; // Current PC output
wire [31:0] pc_next;    // Next PC input
// In SingleCycleCPU, replace the PC instantiation wire with enable:
PC m_PC(
    .clk(clk),
    .rst (start),
    .en (PC_write),   
    .pc_i (pc_next),
    .pc_o (pc_current)
);

wire [31:0] pc_plus4;

Adder m_Adder_1(
    .a(pc_current),
    .b(32'd4),
    .sum(pc_plus4)
);

// output instruction wire
wire [31:0] instruction;
InstructionMemory m_InstMem(
    .readAddr(pc_current),   // address = current PC
    .inst(instruction)       // output instruction
);

// control unit wires
wire branch;
wire memRead;
wire memtoReg;
wire [1:0] ALUOp;
wire memWrite;
wire ALUSrc;
wire regWrite;
wire [2:0] funct3;
wire funct7_bit;
wire EX_flush;

wire jal_sig,jalr_sig;
// register file outputs
wire [31:0] readData1;
wire [31:0] readData2;
wire [31:0] writeData;

//IF/ID pipeline register
reg [31:0] IFID_inst, IFID_pc, IFID_pc4;

//ID/EX pipeline register
reg [31:0] IDEX_pc, IDEX_pc4;
reg [31:0] IDEX_rs1, IDEX_rs2, IDEX_imm, IDEX_imm_shifted;
reg [4:0]  IDEX_rs1_addr, IDEX_rs2_addr, IDEX_rd;
reg [2:0]  IDEX_funct3;
reg  IDEX_funct7;
reg  IDEX_branch, IDEX_memRead, IDEX_memtoReg;
reg [1:0]  IDEX_ALUOp;
reg  IDEX_memWrite, IDEX_ALUSrc, IDEX_regWrite;
reg  IDEX_jal_sig, IDEX_jalr_sig;
reg IDEX_branch_taken;
reg [31:0] IDEX_branch_target;

//EX/MEM pipeline register
reg [31:0] EXMEM_alu_result, EXMEM_rs2;
reg [31:0] EXMEM_branch_target, EXMEM_jalr_target, EXMEM_pc4;
reg [4:0]  EXMEM_rd;
reg  EXMEM_zero, EXMEM_eff_sign, EXMEM_branch_taken;
reg  EXMEM_memRead, EXMEM_memWrite, EXMEM_regWrite;
reg  EXMEM_memtoReg, EXMEM_jal_sig, EXMEM_jalr_sig;

//MEM/WB pipeline register
reg [31:0] MEMWB_mem_data, MEMWB_alu_result, MEMWB_pc4;
reg [4:0]  MEMWB_rd;
reg  MEMWB_regWrite, MEMWB_memtoReg;
reg   MEMWB_jal_sig, MEMWB_jalr_sig;

//IF/ID latch
always@(posedge clk) begin
if(~start) begin
    IFID_inst <= 32'b0;
    IFID_pc <= 32'b0;
    IFID_pc4  <= 32'b0;
end else if(IF_flush) begin
    IFID_inst <= 32'b0;// NOP the instruction
    // We DO NOT zero pc or pc4 — jal still needs its correct pc4 for writeback
end else if(IFID_write) begin
    IFID_inst <= instruction;
    IFID_pc <= pc_current;
    IFID_pc4 <= pc_plus4;
end
//if IFID_write=0, regs hold their previous value (stall)
end

//ID/EX latch
always @(posedge clk) begin
    if (~start || insert_nop) begin
        IDEX_pc   <= 32'b0;
        IDEX_pc4  <= 32'b0;
        IDEX_rs1  <= 32'b0;
        IDEX_rs2   <= 32'b0;
        IDEX_imm   <= 32'b0;
        IDEX_imm_shifted <= 32'b0;
        IDEX_rs1_addr  <= 5'b0;
        IDEX_rs2_addr  <= 5'b0;
        IDEX_rd   <= 5'b0;
        IDEX_funct3  <= 3'b0;
        IDEX_funct7  <= 1'b0;
        IDEX_branch  <= 1'b0;
        IDEX_memRead  <= 1'b0;
        IDEX_memtoReg  <= 1'b0;
        IDEX_ALUOp  <= 2'b0;
        IDEX_memWrite <= 1'b0;
        IDEX_ALUSrc  <= 1'b0;
        IDEX_regWrite <= 1'b0;
        IDEX_jal_sig  <= 1'b0;
        IDEX_jalr_sig  <= 1'b0;
        IDEX_branch_taken <= 1'b0;
    end else begin
        IDEX_pc  <= IFID_pc;
        IDEX_pc4 <= IFID_pc4;
        IDEX_rs1 <= readData1;
        IDEX_rs2 <= readData2;
        IDEX_imm  <= imm;
        IDEX_imm_shifted <= imm_shifted;
        IDEX_rs1_addr  <= IFID_inst[19:15];
        IDEX_rs2_addr <= IFID_inst[24:20];
        IDEX_rd  <= IFID_inst[11:7];
        IDEX_funct3  <= funct3;
        IDEX_funct7  <= funct7_bit;
        IDEX_branch <= branch;
        IDEX_memRead  <= memRead;
        IDEX_memtoReg  <= memtoReg;
        IDEX_ALUOp  <= ALUOp;
        IDEX_memWrite  <= memWrite;
        IDEX_ALUSrc  <= ALUSrc;
        IDEX_regWrite  <= regWrite;
        IDEX_jal_sig  <= jal_sig;
        IDEX_jalr_sig  <= jalr_sig;
        IDEX_branch_taken <= branch_taken;
        IDEX_branch_target <= branch_jal_target;
    end
end

//EX/MEM latch
always @(posedge clk) begin
    if (~start) begin
        EXMEM_alu_result <= 32'b0;
        EXMEM_zero <= 1'b0;
        EXMEM_eff_sign <= 1'b0;
        EXMEM_rs2 <= 32'b0;
        EXMEM_rd <= 5'b0;
        EXMEM_pc4 <= 32'b0;
        EXMEM_branch_target <= 32'b0;
        EXMEM_jalr_target <= 32'b0;
        EXMEM_branch_taken <= 1'b0;
        EXMEM_memRead <= 1'b0;
        EXMEM_memWrite <= 1'b0;
        EXMEM_regWrite <= 1'b0;
        EXMEM_memtoReg <= 1'b0;
        EXMEM_jal_sig  <= 1'b0;
        EXMEM_jalr_sig  <= 1'b0;
    end else begin
        EXMEM_alu_result  <= ALUOut;
        EXMEM_zero  <= zero;
        EXMEM_eff_sign <= eff_sign;
        EXMEM_rs2 <= alu_B_forwarded; //was IDEX_rs2
        EXMEM_rd <= IDEX_rd;
        EXMEM_pc4   <= IDEX_pc4;
        EXMEM_branch_target <= IDEX_branch_target;
        EXMEM_jalr_target <= jalr_target;
        EXMEM_branch_taken  <= branch_taken;
        EXMEM_memRead <= IDEX_memRead;
        EXMEM_memWrite  <= IDEX_memWrite;
        EXMEM_regWrite  <= IDEX_regWrite;
        EXMEM_memtoReg  <= IDEX_memtoReg;
        EXMEM_jal_sig   <= IDEX_jal_sig;
        EXMEM_jalr_sig  <= IDEX_jalr_sig;
    end
end

//MEM/WB latch
always @(posedge clk) begin
    if (~start) begin
        MEMWB_mem_data  <= 32'b0;
        MEMWB_alu_result <= 32'b0;
        MEMWB_rd  <= 5'b0;
        MEMWB_pc4  <= 32'b0;
        MEMWB_regWrite <= 1'b0;
        MEMWB_memtoReg <= 1'b0;
        MEMWB_jal_sig  <= 1'b0;
        MEMWB_jalr_sig  <= 1'b0;
    end else begin
        MEMWB_mem_data  <= memReadData;
        MEMWB_alu_result <= EXMEM_alu_result;
        MEMWB_rd <= EXMEM_rd;
        MEMWB_pc4  <= EXMEM_pc4;
        MEMWB_regWrite  <= EXMEM_regWrite;
        MEMWB_memtoReg  <= EXMEM_memtoReg;
        MEMWB_jal_sig   <= EXMEM_jal_sig;
        MEMWB_jalr_sig  <= EXMEM_jalr_sig;
    end
end


Control m_Control(
    .opcode(IFID_inst[6:0]), // opcode field
    .branch(branch),
    .memRead(memRead),
    .memtoReg(memtoReg),
    .ALUOp(ALUOp),
    .memWrite(memWrite),
    .ALUSrc(ALUSrc),
    .regWrite(regWrite),
    .jal_sig(jal_sig),
    .jalr_sig(jalr_sig)
);




Register m_Register(
    .clk(clk),
    .rst(start),
    .regWrite(MEMWB_regWrite),
    .readReg1(IFID_inst[19:15]),
    .readReg2(IFID_inst[24:20]),
    .writeReg(MEMWB_rd),
    .writeData(writeData),
    .readData1(readData1),
    .readData2(readData2)
);


wire [31:0] imm; // output from immgen unit
ImmGen m_ImmGen(
    .inst(IFID_inst),
    .imm(imm)
);

wire [31:0] imm_shifted; //for branch instructions the immidiate will be shifted left by a bit
ShiftLeftOne m_ShiftLeftOne(
    .i(imm),
    .o(imm_shifted)
);


wire [31:0] branch_jal_target; // this will go to a mux which decides what next PC is.
// branch/jal target adder
Adder m_Adder_2(
    .a(IFID_pc),
    .b(imm),
    .sum(branch_jal_target)
);

wire [31:0] jalr_target_raw;
Adder jalr_adder(.a(alu_A), .b(IDEX_imm), .sum(jalr_target_raw));
wire [31:0] jalr_target = jalr_target_raw & ~32'b1;

wire branch_taken;
//Forward correct rs1/rs2 values for branch comparison in ID stage
reg [31:0] branch_rs1, branch_rs2;

always @(*) begin
    // Forward rs1
    if (IDEX_regWrite && IDEX_rd != 0 && IDEX_rd == IFID_inst[19:15])
        branch_rs1 = (IDEX_jal_sig | IDEX_jalr_sig) ? IDEX_pc4 : ALUOut;
    else if (EXMEM_regWrite && EXMEM_rd != 0 && EXMEM_rd == IFID_inst[19:15])
        branch_rs1 = EXMEM_alu_result;
    else if (MEMWB_regWrite && MEMWB_rd != 0 && MEMWB_rd == IFID_inst[19:15])
        branch_rs1 = writeData;
    else
        branch_rs1 = readData1;

    // Forward rs2
    if (IDEX_regWrite && IDEX_rd != 0 && IDEX_rd == IFID_inst[24:20])
        branch_rs2 = (IDEX_jal_sig | IDEX_jalr_sig) ? IDEX_pc4 : ALUOut;
    else if (EXMEM_regWrite && EXMEM_rd != 0 && EXMEM_rd == IFID_inst[24:20])
        branch_rs2 = EXMEM_alu_result;
    else if (MEMWB_regWrite && MEMWB_rd != 0 && MEMWB_rd == IFID_inst[24:20])
        branch_rs2 = writeData;
    else
        branch_rs2 = readData2;
end
branch_control bcntrl(
    .branch(branch),
    .funct3(funct3),
    .rs1(branch_rs1),   //was readData1
    .rs2(branch_rs2),   //was readData2
    .branch_taken(branch_taken)
);

// w1: branch target (ID stage)
wire [31:0] w1, w2_pc;
// JAL joins branch in ID-stage redirect
wire id_redirect = branch_taken | jal_sig;
// First pick between PC+4 and branch target
Mux2to1 m_Mux_PC0(
    .sel(id_redirect),
    .s0(pc_plus4),
    .s1(branch_jal_target),
    .out(w1)
);

// Then override with jal/jalr if needed (EXMEM stage)
wire mux1cntrl;
assign mux1cntrl = EXMEM_jal_sig | EXMEM_jalr_sig;
Mux2to1 m_Mux_PC1(
    .sel(IDEX_jalr_sig),
    .s0(w1),
    .s1(jalr_target),
    .out(pc_next)
);

reg [31:0] alu_A;  // final A operand into ALU after forwarding
reg [31:0] alu_B_forwarded;  // final B operand after forwarding, before ALUSrc mux

always @(*) begin
    case(forwardA)
        2'b00: alu_A = IDEX_rs1;
        2'b01: alu_A = writeData;
        2'b10: alu_A = (EXMEM_jal_sig | EXMEM_jalr_sig) ? EXMEM_pc4 : EXMEM_alu_result;
        default: alu_A = IDEX_rs1;
    endcase
end

always @(*) begin
    case(forwardB)
        2'b00: alu_B_forwarded = IDEX_rs2;
        2'b01: alu_B_forwarded = writeData;
        2'b10: alu_B_forwarded = (EXMEM_jal_sig | EXMEM_jalr_sig) ? EXMEM_pc4 : EXMEM_alu_result;
        default: alu_B_forwarded = IDEX_rs2;
    endcase
end
//This mux decides B input to the ALU
wire [31:0] alu_B; //goes as input to the ALU
Mux2to1 m_Mux_ALU(
    .sel(IDEX_ALUSrc),
    .s0(alu_B_forwarded),//was IDEX_rs2
    .s1(IDEX_imm),
    .out(alu_B)
);

wire [3:0] ALUCtl;//output of ALU Control unit


assign funct3 = IFID_inst[14:12];
assign funct7_bit = IFID_inst[30];

ALUCtrl m_ALUCtrl(
    .ALUOp(IDEX_ALUOp),
    .funct7(IDEX_funct7),
    .funct3(IDEX_funct3),
    .ALUCtl(ALUCtl)
);

wire [31:0] ALUOut; //output of the ALU
wire zero,eff_sign;
ALU m_ALU(
    .ALUCtl(ALUCtl),
    .A(alu_A), //was IDEX_rs1
    .B(alu_B),
    .ALUOut(ALUOut),
    .zero(zero),
    .eff_sign(eff_sign)
);



wire [31:0] memReadData; //data read out from the data memory when memRead is asserted

DataMemory m_DataMemory(
    .rst(start),
    .clk(clk),
    .memWrite(EXMEM_memWrite),
    .memRead(EXMEM_memRead),
    .address(EXMEM_alu_result),
    .writeData(EXMEM_rs2),  //rs2 value for sw
    .readData(memReadData)   //data read out for lw
);

wire [31:0] w2; //intermediary for writeback mux
Mux2to1 m_Mux_WriteData0(
    .sel(MEMWB_memtoReg),
    .s0(MEMWB_alu_result),
    .s1(MEMWB_mem_data),  //Data memory read output (for lw)
    .out(w2)
);

//additional mux for PC + 4 write backs
Mux2to1 m_Mux_WriteData1(
    .sel(MEMWB_jal_sig | MEMWB_jalr_sig),  //will write back PC + 4 only for jal/jalr
    .s0(w2),        //ALU/Data Memory data
    .s1(MEMWB_pc4),// PC + 4
    .out(writeData)
);

wire [1:0] forwardA, forwardB;

ForwardingUnit m_ForwardingUnit(
    .IDEX_rs1_addr(IDEX_rs1_addr),
    .IDEX_rs2_addr(IDEX_rs2_addr),
    .EXMEM_rd(EXMEM_rd),
    .MEMWB_rd(MEMWB_rd),
    .EXMEM_regWrite(EXMEM_regWrite),
    .MEMWB_regWrite(MEMWB_regWrite),
    .forwardA(forwardA),
    .forwardB(forwardB)
);

wire PC_write, IFID_write, insert_nop, IF_flush;
HazardDetectionUnit m_HazardUnit (
    .IDEX_memRead (IDEX_memRead),
    .IDEX_rd (IDEX_rd),
    .IFID_rs1(IFID_inst[19:15]),
    .IFID_rs2 (IFID_inst[24:20]),
    .branch_taken(branch_taken),
    .jal_sig (jal_sig),
    .IDEX_jalr_sig (IDEX_jalr_sig), 
    .PC_write(PC_write),
    .IFID_write (IFID_write),
    .insert_nop (insert_nop),
    .IF_flush (IF_flush),
    .EX_flush(EX_flush)
);
endmodule
