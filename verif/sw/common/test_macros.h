// Helpers for self-checking assembly tests. A test defines `main`, runs its
// checks and ends with TEST_PASS. t6 is reserved for the checker.
#ifndef TEST_MACROS_H
#define TEST_MACROS_H

#define TEST_PASS \
    li a0, 0;     \
    j _exit

#define TEST_FAIL(n) \
    li a0, n;        \
    j _exit

// Fail with code n unless reg == val.
#define ASSERT_EQ(n, reg, val) \
    li t6, val;                \
    beq reg, t6, 101f;         \
    TEST_FAIL(n);              \
101:

#endif
