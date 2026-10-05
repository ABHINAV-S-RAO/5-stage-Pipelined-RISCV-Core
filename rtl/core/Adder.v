module Adder (
    input signed [31:0] a,
    input signed [31:0] b,
    output signed [31:0] sum
);
    // Adder computes sum = a + b
    // The module is useful for incrementing PC 
    // we will need 2 instantiations of the adder - one for PC + 4 , one for PC + offset
 assign sum = a + b;
endmodule
