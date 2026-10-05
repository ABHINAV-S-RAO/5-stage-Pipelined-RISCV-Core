// HazardDetectionUnit.v
//
// Stalls IF/ID (and bubbles ID/EX) when the instruction in ID needs a value
// that cannot be forwarded yet:
//   1. Load-use: load in EX, consumer in ID (data only exists after MEM).
//   2. Load -> branch/jalr: branches and jalr resolve in ID, so a load that
//      is one stage further (in MEM) still has no data for them. Its data is
//      picked up through the register-file write bypass once it reaches WB.
// Branch mispredict flushes are handled in the top level (gated by stall).
module HazardDetectionUnit (
    input  IDEX_memRead,
    input  [4:0] IDEX_rd,
    input  EXMEM_memRead,
    input  [4:0] EXMEM_rd,
    input  [4:0] IFID_rs1,
    input  [4:0] IFID_rs2,
    input  IFID_useRs1,
    input  IFID_useRs2,
    input  IFID_resolvesInID,  // branch or jalr in ID
    output reg PC_write,
    output reg IFID_write,
    output reg insert_nop,
    output reg load_use_stall,     // for performance counters
    output reg load_branch_stall   // for performance counters
);

wire ex_rs1_hit  = IFID_useRs1 && (IDEX_rd  == IFID_rs1);
wire ex_rs2_hit  = IFID_useRs2 && (IDEX_rd  == IFID_rs2);
wire mem_rs1_hit = IFID_useRs1 && (EXMEM_rd == IFID_rs1);
wire mem_rs2_hit = IFID_useRs2 && (EXMEM_rd == IFID_rs2);

always @(*) begin
    // Load-Use Data Hazard
    load_use_stall    = IDEX_memRead && (IDEX_rd != 0) && (ex_rs1_hit || ex_rs2_hit);
    // Load -> branch/jalr in ID, load currently in MEM
    load_branch_stall = IFID_resolvesInID && EXMEM_memRead && (EXMEM_rd != 0) &&
                        (mem_rs1_hit || mem_rs2_hit);

    PC_write   = ~(load_use_stall || load_branch_stall);
    IFID_write = ~(load_use_stall || load_branch_stall);
    insert_nop =  (load_use_stall || load_branch_stall);
end
endmodule
