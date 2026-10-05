module ALUCtrl (
    input [1:0] ALUOp,
    input funct7,
    input [2:0] funct3,
    output reg [3:0] ALUCtl
);

always @(*) begin
    casex({funct7, funct3, ALUOp})
    6'b000010: ALUCtl = 4'b0010; // add
    6'b100010: ALUCtl = 4'b0110; // sub
    6'b011010: ALUCtl = 4'b0001; // or
    6'b011110: ALUCtl = 4'b0000; // and
    6'b010010: ALUCtl = 4'b0011; // xor
    6'b000110: ALUCtl = 4'b0100; // sll
    6'b010110: ALUCtl = 4'b0101; // srl
    6'b110110: ALUCtl = 4'b0111; // sra
    6'b001010: ALUCtl = 4'b1000; // slt
    6'b001110: ALUCtl = 4'b1001; // sltu
    6'bx00011: ALUCtl = 4'b0010; // addi
    6'bx11111: ALUCtl = 4'b0000; // andi
    6'bx11011: ALUCtl = 4'b0001; // ori
    6'bx10011: ALUCtl = 4'b0011; // xori
    6'b000111: ALUCtl = 4'b0100; // slli
    6'b010111: ALUCtl = 4'b0101; // srli
    6'b110111: ALUCtl = 4'b0111; // srai
    6'bx01011: ALUCtl = 4'b1000; // slti
    6'bx01111: ALUCtl = 4'b1001; // sltiu
    6'bxxxxx0: ALUCtl = 4'b0010; // lw/sw 
    6'bxxxxx1: ALUCtl = 4'b0110; // branch (subtraction)

    default:   ALUCtl = 4'b0000;
endcase
end

endmodule