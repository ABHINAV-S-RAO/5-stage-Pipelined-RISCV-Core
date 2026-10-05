module PC #(
    parameter [31:0] RESET_VECTOR = 32'h8000_0000
)(
    input clk,
    input rst,
    input en,  // enable (stall when 0)
    input  [31:0] pc_i,
    output reg [31:0] pc_o
);
always @(posedge clk) begin
    if (~rst)
        pc_o <= RESET_VECTOR;
    else if (en)  // only advance if not stalled
        pc_o <= pc_i;
end
endmodule
