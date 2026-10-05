# Bare-metal startup shared by all test programs (RTL and Spike).
# Zeroes the register file (Spike's bootrom leaves values in a0/a1/t0),
# sets up gp/sp, clears .bss, calls main and reports main's return value
# through tohost: 0 -> PASS, n -> FAIL with code n.

    .section .text.init, "ax"
    .globl _start
_start:
    li x1, 0
    li x2, 0
    li x3, 0
    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 0
    li x8, 0
    li x9, 0
    li x10, 0
    li x11, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0
    li x16, 0
    li x17, 0
    li x18, 0
    li x19, 0
    li x20, 0
    li x21, 0
    li x22, 0
    li x23, 0
    li x24, 0
    li x25, 0
    li x26, 0
    li x27, 0
    li x28, 0
    li x29, 0
    li x30, 0
    li x31, 0

.option push
.option norelax
    la gp, __global_pointer$
.option pop
    la sp, _stack_top

    la t0, __bss_start
    la t1, __bss_end
1:  bgeu t0, t1, 2f
    sw zero, 0(t0)
    addi t0, t0, 4
    j 1b
2:
    call main

    .globl _exit
_exit:                      # a0 = exit code
    slli a0, a0, 1
    ori  a0, a0, 1
    la   t0, tohost
    sw   a0, 0(t0)
3:  j 3b

# Host interface words polled by Spike (HTIF) and watched by the testbench.
    .section .tohost, "aw", @progbits
    .align 6
    .globl tohost
tohost:   .dword 0
    .align 6
    .globl fromhost
fromhost: .dword 0
