// BRANCH PREDICTOR (2-bit saturating counter, direct-mapped BTB-style)
//
// Indexed by pc_lookup[TABLE_BITS+1:2] (word-aligned index bits). Each entry
// stores: valid bit, tag (remaining PC bits, to detect index aliasing),
// a 2-bit saturating counter (>=2'b10 => predict taken), and a cached
// target address for the branch/jump last seen at that index.
//
// Lookup (IF stage, combinational): given the address about to be fetched,
// predict direction + target.
// Update (ID stage, on clk): once a branch/jump actually resolves, retrain
// the counter and refresh the cached target for its index.
//
// States: 00 strongly not-taken, 01 weakly not-taken,
//         10 weakly taken,       11 strongly taken.
module BranchPredictor2bit #(
    parameter TABLE_BITS = 5   // 2^5 = 32 entries
)(
    input  clk,
    input  rst,

    // IF stage: prediction lookup (combinational read)
    input      [31:0] pc_lookup,
    output             predict_taken,
    output     [31:0] predict_target,

    // ID stage: train with the resolved outcome of a branch/jump
    input              update_en,
    input      [31:0] update_pc,
    input              actual_taken,
    input      [31:0] actual_target
);
    localparam DEPTH    = (1 << TABLE_BITS);
    localparam TAG_BITS = 32 - TABLE_BITS - 2;

    reg [1:0]          counter [0:DEPTH-1];
    reg                valid   [0:DEPTH-1];
    reg [TAG_BITS-1:0] tag     [0:DEPTH-1];
    reg [31:0]         target  [0:DEPTH-1];

    // Read port (IF stage lookup)
    wire [TABLE_BITS-1:0] lookup_idx = pc_lookup[TABLE_BITS+1:2];
    wire [TAG_BITS-1:0]   lookup_tag = pc_lookup[31:TABLE_BITS+2];
    wire                  hit        = valid[lookup_idx] && (tag[lookup_idx] == lookup_tag);

    assign predict_taken  = hit && counter[lookup_idx][1]; // 2'b10/2'b11 => taken
    assign predict_target = target[lookup_idx];

    // Write port (ID stage training)
    wire [TABLE_BITS-1:0] update_idx = update_pc[TABLE_BITS+1:2];
    wire [TAG_BITS-1:0]   update_tag = update_pc[31:TABLE_BITS+2];

    integer i;
    always @(posedge clk) begin
        if (~rst) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                counter[i] <= 2'b01;  // reset to weakly not-taken
                valid[i]   <= 1'b0;
                tag[i]     <= {TAG_BITS{1'b0}};
