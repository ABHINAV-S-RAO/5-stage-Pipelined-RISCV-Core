module branch_control( //updated cuz old one relied on zero and eff_sign which are ALU outputs (Ex stage)
    input branch,
    input [2:0] funct3,
    input [31:0] rs1,
    input [31:0] rs2,
    output reg branch_taken
);
always @(*) begin
    if (branch) begin
        case(funct3)
        3'b000: branch_taken = (rs1 == rs2);              // beq
        3'b001: branch_taken = (rs1 != rs2);              // bne
        3'b100: branch_taken = ($signed(rs1) < $signed(rs2));  // blt
        3'b101: branch_taken = ($signed(rs1) >= $signed(rs2)); // bge
        default: branch_taken = 1'b0;
        endcase
    end
    else begin
        branch_taken = 1'b0;
    end
end
endmodule