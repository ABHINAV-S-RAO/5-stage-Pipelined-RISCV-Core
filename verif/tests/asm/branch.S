// All six conditional branches (taken / not taken, signed vs unsigned
// edges), jal / jalr link values and targets.
#include "test_macros.h"

// Expect branch `op a, b` to be taken / not taken; fail with code n otherwise.
#define EXPECT_TAKEN(n, op, a, b) \
    op a, b, 201f;                \
    TEST_FAIL(n);                 \
201:

#define EXPECT_NOT_TAKEN(n, op, a, b) \
    op a, b, 202f;                    \
    j 203f;                           \
202: TEST_FAIL(n);                    \
203:

    .text
    .globl main
main:
    li   s0, -1          // 0xffffffff
    li   s1, 1
    li   s2, 0x80000000
    li   s3, 0x7fffffff
    li   s4, 1

    EXPECT_TAKEN(1,      beq,  s1, s4)
    EXPECT_NOT_TAKEN(2,  beq,  s0, s1)
    EXPECT_TAKEN(3,      bne,  s0, s1)
    EXPECT_NOT_TAKEN(4,  bne,  s1, s4)

    EXPECT_TAKEN(5,      blt,  s0, s1)    // -1 < 1 signed
    EXPECT_NOT_TAKEN(6,  blt,  s1, s0)
    EXPECT_NOT_TAKEN(7,  blt,  s1, s4)    // equal
    EXPECT_TAKEN(8,      blt,  s2, s3)    // INT_MIN < INT_MAX

    EXPECT_TAKEN(9,      bge,  s1, s0)
    EXPECT_TAKEN(10,     bge,  s1, s4)    // equal
    EXPECT_NOT_TAKEN(11, bge,  s2, s3)

    EXPECT_TAKEN(12,     bltu, s1, s0)    // 1 < 0xffffffff unsigned
    EXPECT_NOT_TAKEN(13, bltu, s0, s1)
    EXPECT_NOT_TAKEN(14, bltu, s1, s4)
    EXPECT_TAKEN(15,     bltu, s3, s2)

    EXPECT_TAKEN(16,     bgeu, s0, s1)
    EXPECT_TAKEN(17,     bgeu, s1, s4)
    EXPECT_NOT_TAKEN(18, bgeu, s3, s2)
    EXPECT_TAKEN(19,     bgeu, zero, zero)

    // ---- backward branch loop (trains the predictor, then exits)
    li   t0, 0
    li   t1, 10
1:  addi t0, t0, 1
    blt  t0, t1, 1b
    ASSERT_EQ(20, t0, 10)

    // ---- jal: link = pc + 4
    jal  ra, 2f
jal_ret:
    j    3f
2:  la   t0, jal_ret
    bne  ra, t0, fail_link
    jr   ra
3:
    // ---- jalr with offset, and with bit 0 set (must be cleared)
    la   t0, jalr_tgt
    addi t0, t0, -8
    jalr ra, 8(t0)
jalr_ret1:
    la   t0, jalr_tgt2
    addi t0, t0, 1
    jalr s5, 0(t0)
jalr_ret2:
    ASSERT_EQ(21, s6, 0x600d)
    la   t0, jalr_ret2
    bne  s5, t0, fail_link
    TEST_PASS

jalr_tgt:
    la   t1, jalr_ret1
    bne  ra, t1, fail_link
    ret
jalr_tgt2:
    li   s6, 0x600d
    jr   s5

fail_link:
    TEST_FAIL(99)
