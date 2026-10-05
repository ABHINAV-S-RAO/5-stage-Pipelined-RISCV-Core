// Byte-lane formatting between the core and a 32-bit word-addressed memory.
// funct3[1:0]: 00 byte, 01 half, 10 word.  funct3[2]: unsigned load.
// Misaligned accesses are not supported (lanes wrap within the word).

// EX stage: place store data on the correct byte lanes and build strobes.
module StoreFormat (
    input             memWrite,
    input      [2:0]  funct3,
    input      [1:0]  addr_lo,
    input      [31:0] rs2_data,
    output reg [3:0]  wstrb,
    output reg [31:0] wdata
);
always @(*) begin
    case (funct3[1:0])
        2'b00:   begin wstrb = 4'b0001 << addr_lo;           wdata = {4{rs2_data[7:0]}};  end // sb
        2'b01:   begin wstrb = 4'b0011 << {addr_lo[1], 1'b0}; wdata = {2{rs2_data[15:0]}}; end // sh
        default: begin wstrb = 4'b1111;                       wdata = rs2_data;            end // sw
    endcase
    if (!memWrite)
        wstrb = 4'b0000;
end
endmodule

// MEM stage: select and extend the loaded byte/half/word.
module LoadFormat (
    input      [2:0]  funct3,
    input      [1:0]  addr_lo,
    input      [31:0] rdata,
    output reg [31:0] load_data
);
wire [31:0] shifted = rdata >> {addr_lo, 3'b000};
always @(*) begin
    case (funct3)
        3'b000:  load_data = {{24{shifted[7]}},  shifted[7:0]};  // lb
        3'b001:  load_data = {{16{shifted[15]}}, shifted[15:0]}; // lh
        3'b100:  load_data = {24'b0, shifted[7:0]};              // lbu
        3'b101:  load_data = {16'b0, shifted[15:0]};             // lhu
        default: load_data = rdata;                              // lw
    endcase
end
endmodule
