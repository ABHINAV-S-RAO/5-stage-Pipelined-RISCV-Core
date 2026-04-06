module InstructionMemory (
    input [31:0] readAddr,
    output [31:0] inst
);
    

    reg [7:0] insts [167:0];

    assign inst = (readAddr >= 168) ? 32'b0 : {insts[readAddr], insts[readAddr + 1], insts[readAddr + 2], insts[readAddr + 3]};

    initial begin
        insts[0] = 8'b0;  insts[1] = 8'b0;  insts[2] = 8'b0;  insts[3] = 8'b0;
        insts[4] = 8'b0;  insts[5] = 8'b0;  insts[6] = 8'b0;  insts[7] = 8'b0;
        insts[8] = 8'b0;  insts[9] = 8'b0;  insts[10] = 8'b0; insts[11] = 8'b0;
        insts[12] = 8'b0; insts[13] = 8'b0; insts[14] = 8'b0; insts[15] = 8'b0;
        insts[16] = 8'b0; insts[17] = 8'b0; insts[18] = 8'b0; insts[19] = 8'b0;
        insts[20] = 8'b0; insts[21] = 8'b0; insts[22] = 8'b0; insts[23] = 8'b0;
        insts[24] = 8'b0; insts[25] = 8'b0; insts[26] = 8'b0; insts[27] = 8'b0;
        insts[28] = 8'b0; insts[29] = 8'b0; insts[30] = 8'b0; insts[31] = 8'b0;
        insts[32] = 8'b0; insts[33] = 8'b0; insts[34] = 8'b0; insts[35] = 8'b0;
        insts[36] = 8'b0; insts[37] = 8'b0; insts[38] = 8'b0; insts[39] = 8'b0;
        insts[40] = 8'b0; insts[41] = 8'b0; insts[42] = 8'b0; insts[43] = 8'b0;
        insts[44] = 8'b0; insts[45] = 8'b0; insts[46] = 8'b0; insts[47] = 8'b0;
        insts[48] = 8'b0; insts[49] = 8'b0; insts[50] = 8'b0; insts[51] = 8'b0;
        $readmemb("TEST_INSTRUCTIONS.dat", insts);
    end

endmodule