module ForwardingUnit (
    input [4:0] IDEX_rs1_addr,
    input [4:0] IDEX_rs2_addr,
    input [4:0] EXMEM_rd,
    input [4:0] MEMWB_rd,
    input EXMEM_regWrite,
    input MEMWB_regWrite,
    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);

always @(*) begin
    forwardA = 2'b00;
    forwardB = 2'b00;

    //EX-EX forwarding (higher priority — checked last so it overrides)
    //MEM-EX forwarding
    if (MEMWB_regWrite & & (MEMWB_rd != 0) && (MEMWB_rd == IDEX_rs1_addr))
        forwardA = 2'b01;
    if (MEMWB_regWrite && (MEMWB_rd != 0) && (MEMWB_rd == IDEX_rs2_addr))
        forwardB = 2'b01;

    //EX-EX forwarding — overrides MEM-EX if both hit
    if (EXMEM_regWrite && (EXMEM_rd != 0) && (EXMEM_rd == IDEX_rs1_addr))
        forwardA = 2'b10;
    if (EXMEM_regWrite && (EXMEM_rd != 0) && (EXMEM_rd == IDEX_rs2_addr))
        forwardB = 2'b10;
end
endmodule