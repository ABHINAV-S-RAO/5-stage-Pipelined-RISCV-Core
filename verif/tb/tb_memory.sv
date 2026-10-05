// Behavioral unified memory with one instruction read port and one data
// read/write port, both synchronous (1-cycle read latency), matching the
// riscv_core memory interface. Loaded from a word-per-line hex image whose
// first word is at BASE.
module tb_memory #(
    parameter [31:0] BASE  = 32'h8000_0000,
    parameter        BYTES = 1 << 20
)(
    input             clk,

    input      [31:0] imem_addr,
    output reg [31:0] imem_rdata,

    input             dmem_re,
    input      [3:0]  dmem_we,
    input      [31:0] dmem_addr,
    input      [31:0] dmem_wdata,
    output reg [31:0] dmem_rdata
);
    localparam WORDS = BYTES / 4;

    reg [31:0] mem [0:WORDS-1];

    function automatic in_range(input [31:0] addr);
        in_range = (addr >= BASE) && (addr - BASE < BYTES);
    endfunction

    function automatic integer widx(input [31:0] addr);
        widx = (addr - BASE) >> 2;
    endfunction

    integer i;
    reg [1023:0] hexfile;
    initial begin
        for (i = 0; i < WORDS; i = i + 1)
            mem[i] = 32'b0;
        if ($value$plusargs("hex=%s", hexfile))
            $readmemh(hexfile, mem);
        else
            $display("[tb_memory] WARNING: no +hex=<file> given, memory is empty");
    end

    always @(posedge clk) begin
        // Wrong-path fetches may run past the image; just return zero.
        imem_rdata <= in_range(imem_addr) ? mem[widx(imem_addr)] : 32'b0;

        if (dmem_re) begin
            if (in_range(dmem_addr))
                dmem_rdata <= mem[widx(dmem_addr)];
            else begin
                dmem_rdata <= 32'b0;
                $display("[tb_memory] ERROR: load from unmapped address 0x%08x at %0t", dmem_addr, $time);
            end
        end

        if (|dmem_we) begin
            if (in_range(dmem_addr)) begin
                if (dmem_we[0]) mem[widx(dmem_addr)][7:0]   <= dmem_wdata[7:0];
                if (dmem_we[1]) mem[widx(dmem_addr)][15:8]  <= dmem_wdata[15:8];
                if (dmem_we[2]) mem[widx(dmem_addr)][23:16] <= dmem_wdata[23:16];
                if (dmem_we[3]) mem[widx(dmem_addr)][31:24] <= dmem_wdata[31:24];
            end else
                $display("[tb_memory] ERROR: store to unmapped address 0x%08x at %0t", dmem_addr, $time);
        end
    end
endmodule
