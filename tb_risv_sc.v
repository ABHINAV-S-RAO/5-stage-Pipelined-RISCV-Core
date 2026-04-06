module tb_riscv_sc;

reg clk;
reg start;

FivestagewithHazard riscv_DUT(clk, start);

initial
    forever #5 clk = ~clk;

initial begin
    clk = 0;
    start = 0;
    #20 start = 1;
    #2500;
    $finish;
end


endmodule
