module ALU (
    input [3:0] ALUCtl,
    input [31:0] A,B,
    output reg [31:0] ALUOut,
    output zero,eff_sign
);
    // ALU has two operand, it execute different operator based on ALUctl wire 
    // output zero is for determining taking branch or not 

    // shift operations done directly in ALU
    wire sign, overflow; //adding sign and overflow flags

    assign zero = (ALUOut == 0);
    assign sign = (ALUOut[31]);
    assign overflow = (A[31] & ~B[31] & ~ALUOut[31]) | (~A[31] & B[31] & ALUOut[31]);
    assign eff_sign = sign^overflow;
    always @(*) begin
    case(ALUCtl)
        4'b0010: ALUOut = A + B;  // add / addi / lw / sw
        4'b0110: ALUOut = A - B;       // sub / beq
        4'b0000: ALUOut = A & B;       // and / andi
        4'b0001: ALUOut = A | B;       // or  / ori
        4'b0011: ALUOut = A ^ B;       // xor / xori
        4'b0100: ALUOut = A << B[4:0]; // sll / slli (only first 5 bits of B are used for shifts)
        4'b0101: ALUOut = A >> B[4:0]; // srl / srli (only first 5 bits of B are used for shifts)
        4'b0111: ALUOut = $signed(A) >>> B[4:0]; // sra / srai
        4'b1000: ALUOut = ($signed(A) < $signed(B)) ? 1 : 0; // slt / slti
        4'b1001: ALUOut = (A < B) ? 1 : 0; // sltu / sltiu
        default: ALUOut = 32'b0;                     
    endcase
    end
endmodule
