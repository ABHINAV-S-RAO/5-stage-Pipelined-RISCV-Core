// Testbench top for riscv_core.
//
// Plusargs:
//   +hex=<file>          program image (one 32-bit word per line, first word at MEM_BASE)
//   +tohost=<hex addr>   address of the 'tohost' symbol; a store there ends the test:
//                        value 1 = PASS, (code << 1) | 1 = FAIL with code
//   +trace=<file>        write a Spike-compatible commit log of retired instructions
//   +max_cycles=<n>      timeout (default 10,000,000)
//   +vcd                 dump waves to waves.vcd
//
// The commit log mirrors `spike --log-commits`, one line per retired instruction:
//   core   0: 3 0x<pc> (0x<inst>) [x<rd> 0x<val>] [mem 0x<addr>] [mem 0x<addr> 0x<data>]
module tb_top;
    parameter [31:0] MEM_BASE  = 32'h8000_0000;
    parameter        MEM_BYTES = 1 << 20;

    reg clk = 1'b0;
    reg rst = 1'b0;   // active low
    always #5 clk = ~clk;

    wire [31:0] imem_addr, imem_rdata;
    wire        dmem_re;
    wire [3:0]  dmem_we;
    wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;

    riscv_core #(.RESET_VECTOR(MEM_BASE)) dut (
        .clk       (clk),
        .rst       (rst),
        .imem_addr (imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_re   (dmem_re),
        .dmem_we   (dmem_we),
        .dmem_addr (dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata)
    );

    tb_memory #(.BASE(MEM_BASE), .BYTES(MEM_BYTES)) mem (
        .clk       (clk),
        .imem_addr (imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_re   (dmem_re),
        .dmem_we   (dmem_we),
        .dmem_addr (dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata)
    );

    // ------------------------------------------------------------------
    // Setup
    // ------------------------------------------------------------------
    reg [31:0]   tohost_addr;
    reg [63:0]   max_cycles;
    reg [1023:0] trace_file;
    integer      trace_fd;

    initial begin
        if (!$value$plusargs("tohost=%h", tohost_addr)) begin
            $display("[tb] ERROR: +tohost=<hex addr> is required");
            $finish;
        end
        if (!$value$plusargs("max_cycles=%d", max_cycles))
            max_cycles = 64'd10_000_000;
        trace_fd = 0;
        if ($value$plusargs("trace=%s", trace_file))
            trace_fd = $fopen(trace_file, "w");
        if ($test$plusargs("vcd")) begin
            $dumpfile("waves.vcd");
            $dumpvars(0, tb_top);
        end

        repeat (5) @(posedge clk);
        rst <= 1'b1;
    end

    // ------------------------------------------------------------------
    // Performance counters (sampled while out of reset)
    // ------------------------------------------------------------------
    reg [63:0] cycles, instret;
    reg [63:0] n_branch, n_branch_taken, n_jal, n_jalr;
    reg [63:0] n_mispredict, n_mispredict_branch, n_mispredict_jal, n_mispredict_jalr;
    reg [63:0] n_load_use_stall, n_load_branch_stall;

    initial begin
        cycles = 0; instret = 0;
        n_branch = 0; n_branch_taken = 0; n_jal = 0; n_jalr = 0;
        n_mispredict = 0; n_mispredict_branch = 0; n_mispredict_jal = 0; n_mispredict_jalr = 0;
        n_load_use_stall = 0; n_load_branch_stall = 0;
    end

    always @(posedge clk) if (rst) begin
        cycles <= cycles + 1;
        if (dut.MEMWB_valid) instret <= instret + 1;
        if (dut.predictor_update_en) begin
            if (dut.branch_ID)    n_branch <= n_branch + 1;
            if (dut.branch_cond)  n_branch_taken <= n_branch_taken + 1;
            if (dut.jump_jal_ID)  n_jal  <= n_jal + 1;
            if (dut.jump_jalr_ID) n_jalr <= n_jalr + 1;
        end
        if (dut.mispredict) begin
            n_mispredict <= n_mispredict + 1;
            if (dut.branch_ID)    n_mispredict_branch <= n_mispredict_branch + 1;
            if (dut.jump_jal_ID)  n_mispredict_jal    <= n_mispredict_jal + 1;
            if (dut.jump_jalr_ID) n_mispredict_jalr   <= n_mispredict_jalr + 1;
        end
        if (dut.load_use_stall)    n_load_use_stall    <= n_load_use_stall + 1;
        if (dut.load_branch_stall) n_load_branch_stall <= n_load_branch_stall + 1;
    end

    // ------------------------------------------------------------------
    // Commit log (WB stage). Sampled before this edge's register updates,
    // i.e. the instruction currently being written back.
    // ------------------------------------------------------------------
    always @(posedge clk) if (rst && dut.MEMWB_valid && trace_fd != 0) begin
        $fwrite(trace_fd, "core   0: 3 0x%08x (0x%08x)", dut.MEMWB_pc, dut.MEMWB_inst);
        if (dut.MEMWB_regWrite && dut.MEMWB_rd != 5'd0) begin
            if (dut.MEMWB_rd < 10)
                $fwrite(trace_fd, " x%0d  0x%08x", dut.MEMWB_rd, dut.writeData_WB);
            else
                $fwrite(trace_fd, " x%0d 0x%08x", dut.MEMWB_rd, dut.writeData_WB);
        end
        if (dut.MEMWB_memtoReg)
            $fwrite(trace_fd, " mem 0x%08x", dut.MEMWB_ALUResult);
        if (dut.MEMWB_memWrite) begin
            case (dut.MEMWB_funct3[1:0])
                2'b00:   $fwrite(trace_fd, " mem 0x%08x 0x%02x", dut.MEMWB_ALUResult, dut.MEMWB_writeData[7:0]);
                2'b01:   $fwrite(trace_fd, " mem 0x%08x 0x%04x", dut.MEMWB_ALUResult, dut.MEMWB_writeData[15:0]);
                default: $fwrite(trace_fd, " mem 0x%08x 0x%08x", dut.MEMWB_ALUResult, dut.MEMWB_writeData);
            endcase
        end
        $fwrite(trace_fd, "\n");
    end

    // ------------------------------------------------------------------
    // End of test: finish when the store to tohost retires, so the commit
    // log ends on exactly the same instruction as Spike's.
    // ------------------------------------------------------------------
    reg [31:0] tohost_value;
    reg        tohost_seen = 1'b0;
    reg        finish_pending = 1'b0;
    reg        test_pass;
    reg [31:0] test_code;

    always @(posedge clk) if (rst && !finish_pending) begin
        if (|dmem_we && dmem_addr == tohost_addr) begin
            tohost_value <= dmem_wdata;
            tohost_seen  <= 1'b1;
        end
        if (tohost_seen && dut.MEMWB_valid && dut.MEMWB_memWrite && dut.MEMWB_ALUResult == tohost_addr) begin
            finish_pending <= 1'b1;
            test_pass      <= (tohost_value == 32'd1);
            test_code      <= tohost_value >> 1;
        end else if (cycles >= max_cycles) begin
            $display("[tb] TIMEOUT after %0d cycles", cycles);
            finish_pending <= 1'b1;
            test_pass      <= 1'b0;
            test_code      <= 32'hffff_ffff;
        end
    end

    // Report on the following negedge, after this edge's logging and
    // counter updates have all completed.
    always @(negedge clk) if (finish_pending) begin
        $display("[STATS] cycles=%0d", cycles);
        $display("[STATS] instret=%0d", instret);
        $display("[STATS] cpi=%0.4f", cycles * 1.0 / instret);
        $display("[STATS] branches=%0d", n_branch);
        $display("[STATS] branches_taken=%0d", n_branch_taken);
        $display("[STATS] jal=%0d", n_jal);
        $display("[STATS] jalr=%0d", n_jalr);
        $display("[STATS] mispredicts=%0d", n_mispredict);
        $display("[STATS] mispredicts_branch=%0d", n_mispredict_branch);
        $display("[STATS] mispredicts_jal=%0d", n_mispredict_jal);
        $display("[STATS] mispredicts_jalr=%0d", n_mispredict_jalr);
        $display("[STATS] load_use_stalls=%0d", n_load_use_stall);
        $display("[STATS] load_branch_stalls=%0d", n_load_branch_stall);
        if (test_pass)
            $display("[tb] PASS");
        else
            $display("[tb] FAIL (code %0d)", test_code);
        if (trace_fd != 0) $fclose(trace_fd);
        $finish;
    end
endmodule
