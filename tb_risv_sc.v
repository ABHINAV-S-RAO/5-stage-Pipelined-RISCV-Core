module tb_riscv_pipeline;
    reg clk, rst;

    PipelinedCPU riscv_DUT (clk, rst);

    initial forever #5 clk = ~clk;

    initial begin
        $dumpfile("riscv_pipeline.vcd");
        $dumpvars(0, tb_riscv_pipeline);
        clk = 0; rst = 0;
        #10 rst = 1;
        #2000 $finish;
    end
endmodule
