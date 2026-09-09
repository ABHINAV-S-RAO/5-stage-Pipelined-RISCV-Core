// HazardDetectionUnit.v
module HazardDetectionUnit (
    input  IDEX_memRead,
    input  [4:0] IDEX_rd,
    input  [4:0] IFID_rs1,
    input  [4:0] IFID_rs2,
    input  mispredict,        // REPLACES branch_taken
    input  IDEX_jalr_sig,
    input  jal_sig,
    output reg PC_write,
    output reg IFID_write,
    output reg insert_nop,
    output reg IF_flush       // Flushes IF/ID only
);

always @(*) begin
    PC_write   = 1'b1;
    IFID_write = 1'b1;
    insert_nop = 1'b0;
    IF_flush   = 1'b0;

    // Load-Use Data Hazard
    if (IDEX_memRead && ((IDEX_rd == IFID_rs1) || (IDEX_rd == IFID_rs2)) && (IDEX_rd != 0)) begin
        PC_write   = 1'b0;
        IFID_write = 1'b0;
        insert_nop = 1'b1;
    end

    // Branch Misprediction Flush (Flushes ONLY IF/ID stage)
    if (mispredict) begin
        IF_flush   = 1'b1;
        // DO NOT set EX_flush or insert_nop here
    end

    // Jumps
    if (jal_sig || IDEX_jalr_sig) begin
        IF_flush   = 1'b1;
    end
end
endmodule