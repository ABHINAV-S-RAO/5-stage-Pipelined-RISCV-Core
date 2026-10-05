// Generated directed test: every RV32I ALU op on edge-case operands.
#include "test_macros.h"

    .text
    .globl main
main:
    li s0, 0x12345678
    li s1, 0xfffffff9
    add a0, s0, s1
    ASSERT_EQ(1, a0, 0x12345671)
    sub a0, s0, s1
    ASSERT_EQ(2, a0, 0x1234567f)
    and a0, s0, s1
    ASSERT_EQ(3, a0, 0x12345678)
    or a0, s0, s1
    ASSERT_EQ(4, a0, 0xfffffff9)
    xor a0, s0, s1
    ASSERT_EQ(5, a0, 0xedcba981)
    sll a0, s0, s1
    ASSERT_EQ(6, a0, 0xf0000000)
    srl a0, s0, s1
    ASSERT_EQ(7, a0, 0x00000009)
    sra a0, s0, s1
    ASSERT_EQ(8, a0, 0x00000009)
    slt a0, s0, s1
    ASSERT_EQ(9, a0, 0x00000000)
    sltu a0, s0, s1
    ASSERT_EQ(10, a0, 0x00000001)
    li s0, 0x80000000
    li s1, 0x00000001
    add a0, s0, s1
    ASSERT_EQ(11, a0, 0x80000001)
    sub a0, s0, s1
    ASSERT_EQ(12, a0, 0x7fffffff)
    and a0, s0, s1
    ASSERT_EQ(13, a0, 0x00000000)
    or a0, s0, s1
    ASSERT_EQ(14, a0, 0x80000001)
    xor a0, s0, s1
    ASSERT_EQ(15, a0, 0x80000001)
    sll a0, s0, s1
    ASSERT_EQ(16, a0, 0x00000000)
    srl a0, s0, s1
    ASSERT_EQ(17, a0, 0x40000000)
    sra a0, s0, s1
    ASSERT_EQ(18, a0, 0xc0000000)
    slt a0, s0, s1
    ASSERT_EQ(19, a0, 0x00000001)
    sltu a0, s0, s1
    ASSERT_EQ(20, a0, 0x00000000)
    li s0, 0x7fffffff
    li s1, 0x00000001
    add a0, s0, s1
    ASSERT_EQ(21, a0, 0x80000000)
    sub a0, s0, s1
    ASSERT_EQ(22, a0, 0x7ffffffe)
    and a0, s0, s1
    ASSERT_EQ(23, a0, 0x00000001)
    or a0, s0, s1
    ASSERT_EQ(24, a0, 0x7fffffff)
    xor a0, s0, s1
    ASSERT_EQ(25, a0, 0x7ffffffe)
    sll a0, s0, s1
    ASSERT_EQ(26, a0, 0xfffffffe)
    srl a0, s0, s1
    ASSERT_EQ(27, a0, 0x3fffffff)
    sra a0, s0, s1
    ASSERT_EQ(28, a0, 0x3fffffff)
    slt a0, s0, s1
    ASSERT_EQ(29, a0, 0x00000000)
    sltu a0, s0, s1
    ASSERT_EQ(30, a0, 0x00000000)
    li s0, 0xffffffff
    li s1, 0xffffffff
    add a0, s0, s1
    ASSERT_EQ(31, a0, 0xfffffffe)
    sub a0, s0, s1
    ASSERT_EQ(32, a0, 0x00000000)
    and a0, s0, s1
    ASSERT_EQ(33, a0, 0xffffffff)
    or a0, s0, s1
    ASSERT_EQ(34, a0, 0xffffffff)
    xor a0, s0, s1
    ASSERT_EQ(35, a0, 0x00000000)
    sll a0, s0, s1
    ASSERT_EQ(36, a0, 0x80000000)
    srl a0, s0, s1
    ASSERT_EQ(37, a0, 0x00000001)
    sra a0, s0, s1
    ASSERT_EQ(38, a0, 0xffffffff)
    slt a0, s0, s1
    ASSERT_EQ(39, a0, 0x00000000)
    sltu a0, s0, s1
    ASSERT_EQ(40, a0, 0x00000000)
    li s0, 0x80000000
    li s1, 0x7fffffff
    add a0, s0, s1
    ASSERT_EQ(41, a0, 0xffffffff)
    sub a0, s0, s1
    ASSERT_EQ(42, a0, 0x00000001)
    and a0, s0, s1
    ASSERT_EQ(43, a0, 0x00000000)
    or a0, s0, s1
    ASSERT_EQ(44, a0, 0xffffffff)
    xor a0, s0, s1
    ASSERT_EQ(45, a0, 0xffffffff)
    sll a0, s0, s1
    ASSERT_EQ(46, a0, 0x00000000)
    srl a0, s0, s1
    ASSERT_EQ(47, a0, 0x00000001)
    sra a0, s0, s1
    ASSERT_EQ(48, a0, 0xffffffff)
    slt a0, s0, s1
    ASSERT_EQ(49, a0, 0x00000001)
    sltu a0, s0, s1
    ASSERT_EQ(50, a0, 0x00000000)
    li s0, 0xdeadbeef
    li s1, 0x0000001f
    add a0, s0, s1
    ASSERT_EQ(51, a0, 0xdeadbf0e)
    sub a0, s0, s1
    ASSERT_EQ(52, a0, 0xdeadbed0)
    and a0, s0, s1
    ASSERT_EQ(53, a0, 0x0000000f)
    or a0, s0, s1
    ASSERT_EQ(54, a0, 0xdeadbeff)
    xor a0, s0, s1
    ASSERT_EQ(55, a0, 0xdeadbef0)
    sll a0, s0, s1
    ASSERT_EQ(56, a0, 0x80000000)
    srl a0, s0, s1
    ASSERT_EQ(57, a0, 0x00000001)
    sra a0, s0, s1
    ASSERT_EQ(58, a0, 0xffffffff)
    slt a0, s0, s1
    ASSERT_EQ(59, a0, 0x00000001)
    sltu a0, s0, s1
    ASSERT_EQ(60, a0, 0x00000000)
    li s0, 0x12345678
    li s1, 0x00000020
    add a0, s0, s1
    ASSERT_EQ(61, a0, 0x12345698)
    sub a0, s0, s1
    ASSERT_EQ(62, a0, 0x12345658)
    and a0, s0, s1
    ASSERT_EQ(63, a0, 0x00000020)
    or a0, s0, s1
    ASSERT_EQ(64, a0, 0x12345678)
    xor a0, s0, s1
    ASSERT_EQ(65, a0, 0x12345658)
    sll a0, s0, s1
    ASSERT_EQ(66, a0, 0x12345678)
    srl a0, s0, s1
    ASSERT_EQ(67, a0, 0x12345678)
    sra a0, s0, s1
    ASSERT_EQ(68, a0, 0x12345678)
    slt a0, s0, s1
    ASSERT_EQ(69, a0, 0x00000000)
    sltu a0, s0, s1
    ASSERT_EQ(70, a0, 0x00000000)
    li s0, 0x00000000
    li s1, 0xffffffff
    add a0, s0, s1
    ASSERT_EQ(71, a0, 0xffffffff)
    sub a0, s0, s1
    ASSERT_EQ(72, a0, 0x00000001)
    and a0, s0, s1
    ASSERT_EQ(73, a0, 0x00000000)
    or a0, s0, s1
    ASSERT_EQ(74, a0, 0xffffffff)
    xor a0, s0, s1
    ASSERT_EQ(75, a0, 0xffffffff)
    sll a0, s0, s1
    ASSERT_EQ(76, a0, 0x00000000)
    srl a0, s0, s1
    ASSERT_EQ(77, a0, 0x00000000)
    sra a0, s0, s1
    ASSERT_EQ(78, a0, 0x00000000)
    slt a0, s0, s1
    ASSERT_EQ(79, a0, 0x00000000)
    sltu a0, s0, s1
    ASSERT_EQ(80, a0, 0x00000001)
    li s0, 0x00000005
    li s1, 0x0000000f
    add a0, s0, s1
    ASSERT_EQ(81, a0, 0x00000014)
    sub a0, s0, s1
    ASSERT_EQ(82, a0, 0xfffffff6)
    and a0, s0, s1
    ASSERT_EQ(83, a0, 0x00000005)
    or a0, s0, s1
    ASSERT_EQ(84, a0, 0x0000000f)
    xor a0, s0, s1
    ASSERT_EQ(85, a0, 0x0000000a)
    sll a0, s0, s1
    ASSERT_EQ(86, a0, 0x00028000)
    srl a0, s0, s1
    ASSERT_EQ(87, a0, 0x00000000)
    sra a0, s0, s1
    ASSERT_EQ(88, a0, 0x00000000)
    slt a0, s0, s1
    ASSERT_EQ(89, a0, 0x00000001)
    sltu a0, s0, s1
    ASSERT_EQ(90, a0, 0x00000001)
    li s0, 0x00000000
    addi a0, s0, 0
    ASSERT_EQ(91, a0, 0x00000000)
    andi a0, s0, 0
    ASSERT_EQ(92, a0, 0x00000000)
    ori a0, s0, 0
    ASSERT_EQ(93, a0, 0x00000000)
    xori a0, s0, 0
    ASSERT_EQ(94, a0, 0x00000000)
    slti a0, s0, 0
    ASSERT_EQ(95, a0, 0x00000000)
    sltiu a0, s0, 0
    ASSERT_EQ(96, a0, 0x00000000)
    addi a0, s0, 1
    ASSERT_EQ(97, a0, 0x00000001)
    andi a0, s0, 1
    ASSERT_EQ(98, a0, 0x00000000)
    ori a0, s0, 1
    ASSERT_EQ(99, a0, 0x00000001)
    xori a0, s0, 1
    ASSERT_EQ(100, a0, 0x00000001)
    slti a0, s0, 1
    ASSERT_EQ(101, a0, 0x00000001)
    sltiu a0, s0, 1
    ASSERT_EQ(102, a0, 0x00000001)
    addi a0, s0, -1
    ASSERT_EQ(103, a0, 0xffffffff)
    andi a0, s0, -1
    ASSERT_EQ(104, a0, 0x00000000)
    ori a0, s0, -1
    ASSERT_EQ(105, a0, 0xffffffff)
    xori a0, s0, -1
    ASSERT_EQ(106, a0, 0xffffffff)
    slti a0, s0, -1
    ASSERT_EQ(107, a0, 0x00000000)
    sltiu a0, s0, -1
    ASSERT_EQ(108, a0, 0x00000001)
    addi a0, s0, 2047
    ASSERT_EQ(109, a0, 0x000007ff)
    andi a0, s0, 2047
    ASSERT_EQ(110, a0, 0x00000000)
    ori a0, s0, 2047
    ASSERT_EQ(111, a0, 0x000007ff)
    xori a0, s0, 2047
    ASSERT_EQ(112, a0, 0x000007ff)
    slti a0, s0, 2047
    ASSERT_EQ(113, a0, 0x00000001)
    sltiu a0, s0, 2047
    ASSERT_EQ(114, a0, 0x00000001)
    addi a0, s0, -2048
    ASSERT_EQ(115, a0, 0xfffff800)
    andi a0, s0, -2048
    ASSERT_EQ(116, a0, 0x00000000)
    ori a0, s0, -2048
    ASSERT_EQ(117, a0, 0xfffff800)
    xori a0, s0, -2048
    ASSERT_EQ(118, a0, 0xfffff800)
    slti a0, s0, -2048
    ASSERT_EQ(119, a0, 0x00000000)
    sltiu a0, s0, -2048
    ASSERT_EQ(120, a0, 0x00000001)
    addi a0, s0, 1365
    ASSERT_EQ(121, a0, 0x00000555)
    andi a0, s0, 1365
    ASSERT_EQ(122, a0, 0x00000000)
    ori a0, s0, 1365
    ASSERT_EQ(123, a0, 0x00000555)
    xori a0, s0, 1365
    ASSERT_EQ(124, a0, 0x00000555)
    slti a0, s0, 1365
    ASSERT_EQ(125, a0, 0x00000001)
    sltiu a0, s0, 1365
    ASSERT_EQ(126, a0, 0x00000001)
    slli a0, s0, 0
    ASSERT_EQ(127, a0, 0x00000000)
    srli a0, s0, 0
    ASSERT_EQ(128, a0, 0x00000000)
    srai a0, s0, 0
    ASSERT_EQ(129, a0, 0x00000000)
    slli a0, s0, 1
    ASSERT_EQ(130, a0, 0x00000000)
    srli a0, s0, 1
    ASSERT_EQ(131, a0, 0x00000000)
    srai a0, s0, 1
    ASSERT_EQ(132, a0, 0x00000000)
    slli a0, s0, 4
    ASSERT_EQ(133, a0, 0x00000000)
    srli a0, s0, 4
    ASSERT_EQ(134, a0, 0x00000000)
    srai a0, s0, 4
    ASSERT_EQ(135, a0, 0x00000000)
    slli a0, s0, 31
    ASSERT_EQ(136, a0, 0x00000000)
    srli a0, s0, 31
    ASSERT_EQ(137, a0, 0x00000000)
    srai a0, s0, 31
    ASSERT_EQ(138, a0, 0x00000000)
    li s0, 0x80000000
    addi a0, s0, 0
    ASSERT_EQ(139, a0, 0x80000000)
    andi a0, s0, 0
    ASSERT_EQ(140, a0, 0x00000000)
    ori a0, s0, 0
    ASSERT_EQ(141, a0, 0x80000000)
    xori a0, s0, 0
    ASSERT_EQ(142, a0, 0x80000000)
    slti a0, s0, 0
    ASSERT_EQ(143, a0, 0x00000001)
    sltiu a0, s0, 0
    ASSERT_EQ(144, a0, 0x00000000)
    addi a0, s0, 1
    ASSERT_EQ(145, a0, 0x80000001)
    andi a0, s0, 1
    ASSERT_EQ(146, a0, 0x00000000)
    ori a0, s0, 1
    ASSERT_EQ(147, a0, 0x80000001)
    xori a0, s0, 1
    ASSERT_EQ(148, a0, 0x80000001)
    slti a0, s0, 1
    ASSERT_EQ(149, a0, 0x00000001)
    sltiu a0, s0, 1
    ASSERT_EQ(150, a0, 0x00000000)
    addi a0, s0, -1
    ASSERT_EQ(151, a0, 0x7fffffff)
    andi a0, s0, -1
    ASSERT_EQ(152, a0, 0x80000000)
    ori a0, s0, -1
    ASSERT_EQ(153, a0, 0xffffffff)
    xori a0, s0, -1
    ASSERT_EQ(154, a0, 0x7fffffff)
    slti a0, s0, -1
    ASSERT_EQ(155, a0, 0x00000001)
    sltiu a0, s0, -1
    ASSERT_EQ(156, a0, 0x00000001)
    addi a0, s0, 2047
    ASSERT_EQ(157, a0, 0x800007ff)
    andi a0, s0, 2047
    ASSERT_EQ(158, a0, 0x00000000)
    ori a0, s0, 2047
    ASSERT_EQ(159, a0, 0x800007ff)
    xori a0, s0, 2047
    ASSERT_EQ(160, a0, 0x800007ff)
    slti a0, s0, 2047
    ASSERT_EQ(161, a0, 0x00000001)
    sltiu a0, s0, 2047
    ASSERT_EQ(162, a0, 0x00000000)
    addi a0, s0, -2048
    ASSERT_EQ(163, a0, 0x7ffff800)
    andi a0, s0, -2048
    ASSERT_EQ(164, a0, 0x80000000)
    ori a0, s0, -2048
    ASSERT_EQ(165, a0, 0xfffff800)
    xori a0, s0, -2048
    ASSERT_EQ(166, a0, 0x7ffff800)
    slti a0, s0, -2048
    ASSERT_EQ(167, a0, 0x00000001)
    sltiu a0, s0, -2048
    ASSERT_EQ(168, a0, 0x00000001)
    addi a0, s0, 1365
    ASSERT_EQ(169, a0, 0x80000555)
    andi a0, s0, 1365
    ASSERT_EQ(170, a0, 0x00000000)
    ori a0, s0, 1365
    ASSERT_EQ(171, a0, 0x80000555)
    xori a0, s0, 1365
    ASSERT_EQ(172, a0, 0x80000555)
    slti a0, s0, 1365
    ASSERT_EQ(173, a0, 0x00000001)
    sltiu a0, s0, 1365
    ASSERT_EQ(174, a0, 0x00000000)
    slli a0, s0, 0
    ASSERT_EQ(175, a0, 0x80000000)
    srli a0, s0, 0
    ASSERT_EQ(176, a0, 0x80000000)
    srai a0, s0, 0
    ASSERT_EQ(177, a0, 0x80000000)
    slli a0, s0, 1
    ASSERT_EQ(178, a0, 0x00000000)
    srli a0, s0, 1
    ASSERT_EQ(179, a0, 0x40000000)
    srai a0, s0, 1
    ASSERT_EQ(180, a0, 0xc0000000)
    slli a0, s0, 4
    ASSERT_EQ(181, a0, 0x00000000)
    srli a0, s0, 4
    ASSERT_EQ(182, a0, 0x08000000)
    srai a0, s0, 4
    ASSERT_EQ(183, a0, 0xf8000000)
    slli a0, s0, 31
    ASSERT_EQ(184, a0, 0x00000000)
    srli a0, s0, 31
    ASSERT_EQ(185, a0, 0x00000001)
    srai a0, s0, 31
    ASSERT_EQ(186, a0, 0xffffffff)
    li s0, 0xffffffff
    addi a0, s0, 0
    ASSERT_EQ(187, a0, 0xffffffff)
    andi a0, s0, 0
    ASSERT_EQ(188, a0, 0x00000000)
    ori a0, s0, 0
    ASSERT_EQ(189, a0, 0xffffffff)
    xori a0, s0, 0
    ASSERT_EQ(190, a0, 0xffffffff)
    slti a0, s0, 0
    ASSERT_EQ(191, a0, 0x00000001)
    sltiu a0, s0, 0
    ASSERT_EQ(192, a0, 0x00000000)
    addi a0, s0, 1
    ASSERT_EQ(193, a0, 0x00000000)
    andi a0, s0, 1
    ASSERT_EQ(194, a0, 0x00000001)
    ori a0, s0, 1
    ASSERT_EQ(195, a0, 0xffffffff)
    xori a0, s0, 1
    ASSERT_EQ(196, a0, 0xfffffffe)
    slti a0, s0, 1
    ASSERT_EQ(197, a0, 0x00000001)
    sltiu a0, s0, 1
    ASSERT_EQ(198, a0, 0x00000000)
    addi a0, s0, -1
    ASSERT_EQ(199, a0, 0xfffffffe)
    andi a0, s0, -1
    ASSERT_EQ(200, a0, 0xffffffff)
    ori a0, s0, -1
    ASSERT_EQ(201, a0, 0xffffffff)
    xori a0, s0, -1
    ASSERT_EQ(202, a0, 0x00000000)
    slti a0, s0, -1
    ASSERT_EQ(203, a0, 0x00000000)
    sltiu a0, s0, -1
    ASSERT_EQ(204, a0, 0x00000000)
    addi a0, s0, 2047
    ASSERT_EQ(205, a0, 0x000007fe)
    andi a0, s0, 2047
    ASSERT_EQ(206, a0, 0x000007ff)
    ori a0, s0, 2047
    ASSERT_EQ(207, a0, 0xffffffff)
    xori a0, s0, 2047
    ASSERT_EQ(208, a0, 0xfffff800)
    slti a0, s0, 2047
    ASSERT_EQ(209, a0, 0x00000001)
    sltiu a0, s0, 2047
    ASSERT_EQ(210, a0, 0x00000000)
    addi a0, s0, -2048
    ASSERT_EQ(211, a0, 0xfffff7ff)
    andi a0, s0, -2048
    ASSERT_EQ(212, a0, 0xfffff800)
    ori a0, s0, -2048
    ASSERT_EQ(213, a0, 0xffffffff)
    xori a0, s0, -2048
    ASSERT_EQ(214, a0, 0x000007ff)
    slti a0, s0, -2048
    ASSERT_EQ(215, a0, 0x00000000)
    sltiu a0, s0, -2048
    ASSERT_EQ(216, a0, 0x00000000)
    addi a0, s0, 1365
    ASSERT_EQ(217, a0, 0x00000554)
    andi a0, s0, 1365
    ASSERT_EQ(218, a0, 0x00000555)
    ori a0, s0, 1365
    ASSERT_EQ(219, a0, 0xffffffff)
    xori a0, s0, 1365
    ASSERT_EQ(220, a0, 0xfffffaaa)
    slti a0, s0, 1365
    ASSERT_EQ(221, a0, 0x00000001)
    sltiu a0, s0, 1365
    ASSERT_EQ(222, a0, 0x00000000)
    slli a0, s0, 0
    ASSERT_EQ(223, a0, 0xffffffff)
    srli a0, s0, 0
    ASSERT_EQ(224, a0, 0xffffffff)
    srai a0, s0, 0
    ASSERT_EQ(225, a0, 0xffffffff)
    slli a0, s0, 1
    ASSERT_EQ(226, a0, 0xfffffffe)
    srli a0, s0, 1
    ASSERT_EQ(227, a0, 0x7fffffff)
    srai a0, s0, 1
    ASSERT_EQ(228, a0, 0xffffffff)
    slli a0, s0, 4
    ASSERT_EQ(229, a0, 0xfffffff0)
    srli a0, s0, 4
    ASSERT_EQ(230, a0, 0x0fffffff)
    srai a0, s0, 4
    ASSERT_EQ(231, a0, 0xffffffff)
    slli a0, s0, 31
    ASSERT_EQ(232, a0, 0x80000000)
    srli a0, s0, 31
    ASSERT_EQ(233, a0, 0x00000001)
    srai a0, s0, 31
    ASSERT_EQ(234, a0, 0xffffffff)
    li s0, 0x12345678
    addi a0, s0, 0
    ASSERT_EQ(235, a0, 0x12345678)
    andi a0, s0, 0
    ASSERT_EQ(236, a0, 0x00000000)
    ori a0, s0, 0
    ASSERT_EQ(237, a0, 0x12345678)
    xori a0, s0, 0
    ASSERT_EQ(238, a0, 0x12345678)
    slti a0, s0, 0
    ASSERT_EQ(239, a0, 0x00000000)
    sltiu a0, s0, 0
    ASSERT_EQ(240, a0, 0x00000000)
    addi a0, s0, 1
    ASSERT_EQ(241, a0, 0x12345679)
    andi a0, s0, 1
    ASSERT_EQ(242, a0, 0x00000000)
    ori a0, s0, 1
    ASSERT_EQ(243, a0, 0x12345679)
    xori a0, s0, 1
    ASSERT_EQ(244, a0, 0x12345679)
    slti a0, s0, 1
    ASSERT_EQ(245, a0, 0x00000000)
    sltiu a0, s0, 1
    ASSERT_EQ(246, a0, 0x00000000)
    addi a0, s0, -1
    ASSERT_EQ(247, a0, 0x12345677)
    andi a0, s0, -1
    ASSERT_EQ(248, a0, 0x12345678)
    ori a0, s0, -1
    ASSERT_EQ(249, a0, 0xffffffff)
    xori a0, s0, -1
    ASSERT_EQ(250, a0, 0xedcba987)
    slti a0, s0, -1
    ASSERT_EQ(251, a0, 0x00000000)
    sltiu a0, s0, -1
    ASSERT_EQ(252, a0, 0x00000001)
    addi a0, s0, 2047
    ASSERT_EQ(253, a0, 0x12345e77)
    andi a0, s0, 2047
    ASSERT_EQ(254, a0, 0x00000678)
    ori a0, s0, 2047
    ASSERT_EQ(255, a0, 0x123457ff)
    xori a0, s0, 2047
    ASSERT_EQ(256, a0, 0x12345187)
    slti a0, s0, 2047
    ASSERT_EQ(257, a0, 0x00000000)
    sltiu a0, s0, 2047
    ASSERT_EQ(258, a0, 0x00000000)
    addi a0, s0, -2048
    ASSERT_EQ(259, a0, 0x12344e78)
    andi a0, s0, -2048
    ASSERT_EQ(260, a0, 0x12345000)
    ori a0, s0, -2048
    ASSERT_EQ(261, a0, 0xfffffe78)
    xori a0, s0, -2048
    ASSERT_EQ(262, a0, 0xedcbae78)
    slti a0, s0, -2048
    ASSERT_EQ(263, a0, 0x00000000)
    sltiu a0, s0, -2048
    ASSERT_EQ(264, a0, 0x00000001)
    addi a0, s0, 1365
    ASSERT_EQ(265, a0, 0x12345bcd)
    andi a0, s0, 1365
    ASSERT_EQ(266, a0, 0x00000450)
    ori a0, s0, 1365
    ASSERT_EQ(267, a0, 0x1234577d)
    xori a0, s0, 1365
    ASSERT_EQ(268, a0, 0x1234532d)
    slti a0, s0, 1365
    ASSERT_EQ(269, a0, 0x00000000)
    sltiu a0, s0, 1365
    ASSERT_EQ(270, a0, 0x00000000)
    slli a0, s0, 0
    ASSERT_EQ(271, a0, 0x12345678)
    srli a0, s0, 0
    ASSERT_EQ(272, a0, 0x12345678)
    srai a0, s0, 0
    ASSERT_EQ(273, a0, 0x12345678)
    slli a0, s0, 1
    ASSERT_EQ(274, a0, 0x2468acf0)
    srli a0, s0, 1
    ASSERT_EQ(275, a0, 0x091a2b3c)
    srai a0, s0, 1
    ASSERT_EQ(276, a0, 0x091a2b3c)
    slli a0, s0, 4
    ASSERT_EQ(277, a0, 0x23456780)
    srli a0, s0, 4
    ASSERT_EQ(278, a0, 0x01234567)
    srai a0, s0, 4
    ASSERT_EQ(279, a0, 0x01234567)
    slli a0, s0, 31
    ASSERT_EQ(280, a0, 0x00000000)
    srli a0, s0, 31
    ASSERT_EQ(281, a0, 0x00000000)
    srai a0, s0, 31
    ASSERT_EQ(282, a0, 0x00000000)
    li s0, 0x7fffffff
    addi a0, s0, 0
    ASSERT_EQ(283, a0, 0x7fffffff)
    andi a0, s0, 0
    ASSERT_EQ(284, a0, 0x00000000)
    ori a0, s0, 0
    ASSERT_EQ(285, a0, 0x7fffffff)
    xori a0, s0, 0
    ASSERT_EQ(286, a0, 0x7fffffff)
    slti a0, s0, 0
    ASSERT_EQ(287, a0, 0x00000000)
    sltiu a0, s0, 0
    ASSERT_EQ(288, a0, 0x00000000)
    addi a0, s0, 1
    ASSERT_EQ(289, a0, 0x80000000)
    andi a0, s0, 1
    ASSERT_EQ(290, a0, 0x00000001)
    ori a0, s0, 1
    ASSERT_EQ(291, a0, 0x7fffffff)
    xori a0, s0, 1
    ASSERT_EQ(292, a0, 0x7ffffffe)
    slti a0, s0, 1
    ASSERT_EQ(293, a0, 0x00000000)
    sltiu a0, s0, 1
    ASSERT_EQ(294, a0, 0x00000000)
    addi a0, s0, -1
    ASSERT_EQ(295, a0, 0x7ffffffe)
    andi a0, s0, -1
    ASSERT_EQ(296, a0, 0x7fffffff)
    ori a0, s0, -1
    ASSERT_EQ(297, a0, 0xffffffff)
    xori a0, s0, -1
    ASSERT_EQ(298, a0, 0x80000000)
    slti a0, s0, -1
    ASSERT_EQ(299, a0, 0x00000000)
    sltiu a0, s0, -1
    ASSERT_EQ(300, a0, 0x00000001)
    addi a0, s0, 2047
    ASSERT_EQ(301, a0, 0x800007fe)
    andi a0, s0, 2047
    ASSERT_EQ(302, a0, 0x000007ff)
    ori a0, s0, 2047
    ASSERT_EQ(303, a0, 0x7fffffff)
    xori a0, s0, 2047
    ASSERT_EQ(304, a0, 0x7ffff800)
    slti a0, s0, 2047
    ASSERT_EQ(305, a0, 0x00000000)
    sltiu a0, s0, 2047
    ASSERT_EQ(306, a0, 0x00000000)
    addi a0, s0, -2048
    ASSERT_EQ(307, a0, 0x7ffff7ff)
    andi a0, s0, -2048
    ASSERT_EQ(308, a0, 0x7ffff800)
    ori a0, s0, -2048
    ASSERT_EQ(309, a0, 0xffffffff)
    xori a0, s0, -2048
    ASSERT_EQ(310, a0, 0x800007ff)
    slti a0, s0, -2048
    ASSERT_EQ(311, a0, 0x00000000)
    sltiu a0, s0, -2048
    ASSERT_EQ(312, a0, 0x00000001)
    addi a0, s0, 1365
    ASSERT_EQ(313, a0, 0x80000554)
    andi a0, s0, 1365
    ASSERT_EQ(314, a0, 0x00000555)
    ori a0, s0, 1365
    ASSERT_EQ(315, a0, 0x7fffffff)
    xori a0, s0, 1365
    ASSERT_EQ(316, a0, 0x7ffffaaa)
    slti a0, s0, 1365
    ASSERT_EQ(317, a0, 0x00000000)
    sltiu a0, s0, 1365
    ASSERT_EQ(318, a0, 0x00000000)
    slli a0, s0, 0
    ASSERT_EQ(319, a0, 0x7fffffff)
    srli a0, s0, 0
    ASSERT_EQ(320, a0, 0x7fffffff)
    srai a0, s0, 0
    ASSERT_EQ(321, a0, 0x7fffffff)
    slli a0, s0, 1
    ASSERT_EQ(322, a0, 0xfffffffe)
    srli a0, s0, 1
    ASSERT_EQ(323, a0, 0x3fffffff)
    srai a0, s0, 1
    ASSERT_EQ(324, a0, 0x3fffffff)
    slli a0, s0, 4
    ASSERT_EQ(325, a0, 0xfffffff0)
    srli a0, s0, 4
    ASSERT_EQ(326, a0, 0x07ffffff)
    srai a0, s0, 4
    ASSERT_EQ(327, a0, 0x07ffffff)
    slli a0, s0, 31
    ASSERT_EQ(328, a0, 0x80000000)
    srli a0, s0, 31
    ASSERT_EQ(329, a0, 0x00000000)
    srai a0, s0, 31
    ASSERT_EQ(330, a0, 0x00000000)
    lui a0, 0x0
    ASSERT_EQ(331, a0, 0x00000000)
    lui a0, 0x1
    ASSERT_EQ(332, a0, 0x00001000)
    lui a0, 0x80000
    ASSERT_EQ(333, a0, 0x80000000)
    lui a0, 0xfffff
    ASSERT_EQ(334, a0, 0xfffff000)
    lui a0, 0x12345
    ASSERT_EQ(335, a0, 0x12345000)
    // auipc: compare against the label address computed by la
1:  auipc a0, 0
    la a1, 1b
    bne a0, a1, auipc_fail
2:  auipc a0, 0x10
    la a1, 2b
    li t0, 0x10000
    add a1, a1, t0
    bne a0, a1, auipc_fail
    // writes to x0 must be discarded
    addi x0, x0, 5
    lui x0, 0x12345
    ASSERT_EQ(336, x0, 0)
    TEST_PASS
auipc_fail:
    TEST_FAIL(337)
