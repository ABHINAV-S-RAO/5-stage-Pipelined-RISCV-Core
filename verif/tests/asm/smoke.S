// Original TEST_INSTRUCTIONS.dat program, ported to the new flow with checks.
#include "test_macros.h"

    .text
    .globl main
main:
    li   ra, 15
    li   sp, 5
    add  gp, ra, sp
    sub  tp, ra, sp
    and  t0, ra, sp
    or   t1, ra, sp
    xor  t2, ra, sp
    sll  s0, ra, sp
    srl  s1, ra, sp
    slt  a0, sp, ra
    la   a7, scratch
    sw   gp, 0(a7)
    lw   a2, 0(a7)
    add  a3, a2, ra          // load-use
    li   a1, 5
    li   a4, 0
loop:
    add  a4, a4, a1
    addi a1, a1, -1
    bnez a1, loop
    jal  ra, target
    nop
target:
    li   a5, 100

    ASSERT_EQ(1,  gp, 20)
    ASSERT_EQ(2,  tp, 10)
    ASSERT_EQ(3,  t0, 5)
    ASSERT_EQ(4,  t1, 15)
    ASSERT_EQ(5,  t2, 10)
    ASSERT_EQ(6,  s0, 480)
    ASSERT_EQ(7,  s1, 0)
    ASSERT_EQ(8,  a0, 1)
    ASSERT_EQ(9,  a2, 20)
    ASSERT_EQ(10, a3, 35)
    ASSERT_EQ(11, a4, 15)
    ASSERT_EQ(12, a5, 100)
    TEST_PASS

    .data
scratch: .word 0
