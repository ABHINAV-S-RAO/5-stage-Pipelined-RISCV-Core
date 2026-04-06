module Mux2to1 (
    input sel,
    input signed [31:0] s0,
    input signed [31:0] s1,
    output signed [31:0] out
);
assign out = sel ? s1 : s0;
endmodule