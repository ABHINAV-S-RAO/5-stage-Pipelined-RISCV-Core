module Control (
    input [6:0] opcode,
    output reg branch,
    output reg memRead,
    output reg memtoReg,
    output reg [1:0] ALUOp,
    output reg memWrite,
    output reg ALUSrc,
    output reg regWrite,
    output jal_sig,
    output jalr_sig
    );
    assign jal_sig = (opcode == 7'b1101111);
    assign jalr_sig =  (opcode == 7'b1100111);
    // TODO: implement your Control here
    
    always @(*) begin
	casex(opcode)

    /*R-type instruction*/ 
    7'b0110011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000001;
    ALUOp = 2'b10;
    end 

    /*Arithmetic I-Type instruction*/
    7'b0010011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000011;
    ALUOp = 2'b11;   
    end   

    /*Load I-type instruction*/
    7'b0000011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b011011;
    ALUOp = 2'b00;
    end

    /*S-Type instruction*/
    7'b0100011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000110;
    ALUOp = 2'b00;
    end      

    /*SB-type instruction*/
    7'b1100011 :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b100000;  
    ALUOp = 2'b01;
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
    end
    
    default :begin
    {branch,memRead,memtoReg,memWrite,ALUSrc,regWrite} = 6'b000000;
    ALUOp = 2'b00;   
    end 

    endcase
end

endmodule