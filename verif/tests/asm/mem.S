// Loads and stores of every width, sign/zero extension, every byte offset.
#include "test_macros.h"

    .text
    .globl main
main:
    la   s0, buf

    // ---- loads from a known pattern: 0x8899aabb at buf, 0x11223344 at buf+4
    lw   a0, 0(s0)
    ASSERT_EQ(1, a0, 0x8899aabb)
    lb   a0, 0(s0)
    ASSERT_EQ(2, a0, 0xffffffbb)
    lb   a0, 1(s0)
    ASSERT_EQ(3, a0, 0xffffffaa)
    lb   a0, 2(s0)
    ASSERT_EQ(4, a0, 0xffffff99)
    lb   a0, 3(s0)
    ASSERT_EQ(5, a0, 0xffffff88)
    lbu  a0, 0(s0)
    ASSERT_EQ(6, a0, 0xbb)
    lbu  a0, 3(s0)
    ASSERT_EQ(7, a0, 0x88)
    lh   a0, 0(s0)
    ASSERT_EQ(8, a0, 0xffffaabb)
    lh   a0, 2(s0)
    ASSERT_EQ(9, a0, 0xffff8899)
    lhu  a0, 0(s0)
    ASSERT_EQ(10, a0, 0xaabb)
    lhu  a0, 2(s0)
    ASSERT_EQ(11, a0, 0x8899)
    lb   a0, 4(s0)
    ASSERT_EQ(12, a0, 0x44)
    lh   a0, 6(s0)
    ASSERT_EQ(13, a0, 0x1122)
    lw   a0, 4(s0)
    ASSERT_EQ(14, a0, 0x11223344)

    // ---- negative offsets
    addi s1, s0, 8
    lw   a0, -8(s1)
    ASSERT_EQ(15, a0, 0x8899aabb)
    lbu  a0, -1(s1)
    ASSERT_EQ(16, a0, 0x11)

    // ---- byte stores into each lane
    sw   zero, 8(s0)
    li   t0, 0xa1
    sb   t0, 8(s0)
    li   t0, 0xb2
    sb   t0, 9(s0)
    li   t0, 0xc3
    sb   t0, 10(s0)
    li   t0, 0x1234ffd4     // only the low byte may be written
    sb   t0, 11(s0)
    lw   a0, 8(s0)
    ASSERT_EQ(17, a0, 0xd4c3b2a1)

    // ---- half stores into each half
    sw   zero, 12(s0)
    li   t0, 0xdead5678
    sh   t0, 12(s0)
    li   t0, 0xbeef1234
    sh   t0, 14(s0)
    lw   a0, 12(s0)
    ASSERT_EQ(18, a0, 0x12345678)

    // ---- byte store must not disturb neighbours
    li   t0, 0x11223344
    sw   t0, 16(s0)
    li   t0, 0xff
    sb   t0, 17(s0)
    lw   a0, 16(s0)
    ASSERT_EQ(19, a0, 0x1122ff44)
    lhu  a0, 16(s0)
    ASSERT_EQ(20, a0, 0xff44)

    // ---- store then immediately load the same address
    li   t0, 0x5a5a5a5a
    sw   t0, 20(s0)
    lw   a0, 20(s0)
    ASSERT_EQ(21, a0, 0x5a5a5a5a)
    sb   zero, 20(s0)
    lw   a0, 20(s0)
    ASSERT_EQ(22, a0, 0x5a5a5a00)

    // ---- load to x0 is discarded
    lw   zero, 0(s0)
    ASSERT_EQ(23, zero, 0)

    TEST_PASS

    .data
    .align 2
buf:
    .word 0x8899aabb
    .word 0x11223344
    .space 32
