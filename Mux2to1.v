module Mux2to1 (
    input sel,
    input signed [31:0] s0,
    input signed [31:0] s1,
    output signed [31:0] out
);
assign out = sel ? s1 : s0;
endmodule

module Mux3to1 #(
    parameter WIDTH = 32
)(
    input  [1:0]       sel,
    input  [WIDTH-1:0] in0, // 2'b00: Original RS value
    input  [WIDTH-1:0] in1, // 2'b01: Forwarded from MEM/WB
    input  [WIDTH-1:0] in2, // 2'b10: Forwarded from EX/MEM
    output reg [WIDTH-1:0] out
);
    always @(*) begin
        case (sel)
            2'b00:   out = in0;
            2'b01:   out = in1;
            2'b10:   out = in2;
            default: out = in0;
        endcase
    end
endmodule