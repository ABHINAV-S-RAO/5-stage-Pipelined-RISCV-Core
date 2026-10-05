// Pipeline hazard stress: every forwarding path, load-use and load->branch
// stalls, branches/jalr whose operands are still in flight, link-register
// forwarding, and predictor training/mispredicts.
#include "test_macros.h"

    .text
    .globl main
main:
    la   s0, data

    // ---- EX/MEM -> EX forwarding (back-to-back dependency), both operands
    li   a0, 3
    add  a1, a0, a0
    add  a2, a1, a1
    ASSERT_EQ(1, a2, 12)

    // ---- MEM/WB -> EX forwarding (one instruction in between)
    li   a0, 7
    nop
    add  a1, a0, zero
    ASSERT_EQ(2, a1, 7)

    // ---- register-file bypass (two instructions in between)
    li   a0, 9
    nop
    nop
    add  a1, a0, zero
    ASSERT_EQ(3, a1, 9)

    // ---- EX/MEM must win over MEM/WB for the same register
    li   a0, 1
    li   a0, 2
    add  a1, a0, zero
    ASSERT_EQ(4, a1, 2)

    // ---- load-use on rs1 and rs2
    lw   a0, 0(s0)              // 5
    add  a1, a0, zero
    ASSERT_EQ(5, a1, 5)
    lw   a0, 0(s0)
    add  a1, zero, a0
    ASSERT_EQ(6, a1, 5)

    // ---- load -> store data (rs2) and load -> store address (rs1)
    lw   a0, 0(s0)
    sw   a0, 8(s0)
    lw   a1, 8(s0)
    ASSERT_EQ(7, a1, 5)
    lw   a2, 4(s0)              // a2 = address of data
    sw   a0, 12(a2)
    lw   a1, 12(s0)
    ASSERT_EQ(8, a1, 5)

    // ---- load -> load address chain
    lw   a0, 4(s0)              // &data
    lw   a1, 0(a0)
    ASSERT_EQ(9, a1, 5)

    // ---- ALU result -> branch in the very next instruction (ID forwarding from EX)
    li   a0, 4
    addi a1, a0, 1
    li   t0, 5
    beq  a1, t0, 1f
    TEST_FAIL(10)
1:
    // ---- ALU -> branch with one instruction between (forward from EX/MEM)
    li   a0, 4
    addi a1, a0, 2
    nop
    li   t0, 6
    bne  a1, t0, fail11
    j    2f
fail11:
    TEST_FAIL(11)
2:
    // ---- load -> branch immediately (needs 2 stall cycles)
    lw   a0, 0(s0)
    li   t0, 5
    bne  a0, t0, fail12
    // ---- load -> branch with one instruction between (needs 1 stall cycle)
    lw   a0, 0(s0)
    nop
    beq  a0, zero, fail12
    // ---- load -> branch on rs2
    lw   a0, 0(s0)
    blt  zero, a0, 3f
fail12:
    TEST_FAIL(12)
3:
    // ---- load -> jalr target
    lw   a0, 16(s0)             // &jalr_target
    jalr ra, 0(a0)
    ASSERT_EQ(13, s1, 0x77)
    // ---- ALU -> jalr target
    la   a0, jalr_target
    addi a0, a0, 0
    jalr ra, 0(a0)
    ASSERT_EQ(14, s1, 0x77)

    // ---- link register used right after the jump returns
    jal  ra, link_fn
link_ret:
    la   t0, link_ret
    bne  a3, t0, fail15
    // ---- jal link value forwarded to a branch in ID
    jal  t1, 4f
4:  la   t0, 4b
    bne  t1, t0, fail15
    j    5f
fail15:
    TEST_FAIL(15)
5:
    // ---- the jalr result itself (link) forwarded into the next ALU op
    la   t0, ret_imm
    jalr t2, 0(t0)
after_jalr:
    j 6f
ret_imm:
    addi a4, t2, 0              // t2 must already hold after_jalr
    la   t0, after_jalr
    bne  a4, t0, fail16
    jr   t2
fail16:
    TEST_FAIL(16)
6:
    // ---- data-dependent loop: alternating taken/not-taken branches
    li   t0, 0                  // i
    li   t1, 0                  // sum of even i
    li   t2, 16
7:  andi t3, t0, 1
    bnez t3, 8f
    add  t1, t1, t0
8:  addi t0, t0, 1
    blt  t0, t2, 7b
    ASSERT_EQ(17, t1, 56)       // 0+2+...+14

    // ---- nested loops (predictor aliasing / retraining)
    li   t0, 0
    li   t4, 0
9:  li   t1, 0
10: addi t4, t4, 1
    addi t1, t1, 1
    li   t3, 3
    blt  t1, t3, 10b
    addi t0, t0, 1
    li   t3, 4
    blt  t0, t3, 9b
    ASSERT_EQ(18, t4, 12)

    // ---- function calls in a loop (jal/ret predicted through the BTB)
    li   s2, 0
    li   s3, 0
11: jal  ra, inc_fn
    addi s3, s3, 1
    li   t0, 5
    blt  s3, t0, 11b
    ASSERT_EQ(19, s2, 5)

    // ---- store -> load to same address with forwarding into the store data
    li   a0, 0x1234
    addi a0, a0, 1
    sw   a0, 20(s0)
    lw   a1, 20(s0)
    ASSERT_EQ(20, a1, 0x1235)

    // ---- writes to x0 must never be forwarded
    li   a0, 0
    addi zero, zero, 5
    add  a1, zero, zero
    ASSERT_EQ(21, a1, 0)
    lw   zero, 0(s0)
    add  a1, zero, zero
    ASSERT_EQ(22, a1, 0)

    TEST_PASS

jalr_target:
    li   s1, 0x77
    ret

link_fn:
    mv   a3, ra
    ret

inc_fn:
    addi s2, s2, 1
    ret

    .data
    .align 2
data:
    .word 5                     // +0
    .word data                  // +4
    .word 0                     // +8
    .word 0                     // +12
    .word jalr_target           // +16
    .word 0                     // +20
    .word 0
