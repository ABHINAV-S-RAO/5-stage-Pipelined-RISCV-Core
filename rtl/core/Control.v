module Control (
    input [6:0] opcode,
    output reg branch,
    output reg memRead,
    output reg memtoReg,
    output reg [1:0] ALUOp,
    output reg memWrite,
    output reg ALUSrc,
    output reg regWrite,
    output reg [1:0] ALUSrcA,   // 00: rs1, 01: pc (auipc), 10: zero (lui)
    output reg useRs1,          // instruction actually reads rs1 (for hazard detection)
    output reg useRs2,          // instruction actually reads rs2 (for hazard detection)
    output jal_sig,
    output jalr_sig
    );
    assign jal_sig = (opcode == 7'b1101111);
    assign jalr_sig =  (opcode == 7'b1100111);

    always @(*) begin
    ALUSrcA = 2'b00;
    {useRs1, useRs2} = 2'b00;
	casex(opcode)

    /*R-type instruction*/
    7'b0110011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000001;
    ALUOp = 2'b10;
    {useRs1, useRs2} = 2'b11;
    end

    /*Arithmetic I-Type instruction*/
    7'b0010011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000011;
    ALUOp = 2'b11;
    {useRs1, useRs2} = 2'b10;
    end

    /*Load I-type instruction*/
    7'b0000011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b011011;
    ALUOp = 2'b00;
    {useRs1, useRs2} = 2'b10;
    end

    /*S-Type instruction*/
    7'b0100011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000110;
    ALUOp = 2'b00;
    {useRs1, useRs2} = 2'b11;
    end

    /*SB-type instruction*/
    7'b1100011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b100000;
    ALUOp = 2'b01;
    {useRs1, useRs2} = 2'b11;
    end

    /* UJ-type instruction (jal) */
    7'b1101111 : begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000001;
    ALUOp = 2'b00;
    end

    /* I-type Jump instruction (jalr) */
    7'b1100111 : begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000011;
    ALUOp = 2'b00;  // (rs1 + imm)
    {useRs1, useRs2} = 2'b10;
    end

    /* U-type lui: rd = 0 + imm */
    7'b0110111 : begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000011;
    ALUOp = 2'b00;
    ALUSrcA = 2'b10;
    end

    /* U-type auipc: rd = pc + imm */
    7'b0010111 : begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000011;
    ALUOp = 2'b00;
    ALUSrcA = 2'b01;
    end

    /* fence / ecall / ebreak / unknown: executed as nop */
    default :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000000;
    ALUOp = 2'b00;
    end

    endcase
end

endmodule
