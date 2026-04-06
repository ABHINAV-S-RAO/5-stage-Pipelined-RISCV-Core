module ImmGen (
    input [31:0] inst,
    output reg signed [31:0] imm
);
    wire [6:0] opcode = inst[6:0];

    always @(*) begin
        case(opcode)
            7'b0010011: imm = {{20{inst[31]}}, inst[31:20]}; //arithmetic I-type
            7'b0000011: imm = {{20{inst[31]}}, inst[31:20]}; //load I-type (lw)
            7'b0100011: imm = {{20{inst[31]}},inst[31:25],inst[11:7]}; // S-type (sw)
            7'b1100011: imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0}; // SB-type (beq)
            7'b1101111: imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}; // UJ-type
            7'b1100111: imm = {{20{inst[31]}}, inst[31:20]}; // I-type (JALR)
            default:
                imm = 32'b0; // default 0 for others
        endcase
    end
endmodule