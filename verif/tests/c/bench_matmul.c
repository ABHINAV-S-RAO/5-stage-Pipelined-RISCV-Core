// 10x10 integer matrix multiply. RV32I has no MUL, so every multiply is a
// call into libgcc's __mulsi3 (a shift-and-add loop): call/return heavy with
// short inner loops. Expected checksum computed offline in Python.
#define N 10
#define EXPECTED 0x2df7e591u

static int A[N][N], B[N][N], C[N][N];

static unsigned xorshift(unsigned *s)
{
    unsigned x = *s;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    return *s = x;
}

int main(void)
{
    unsigned s = 0x12345678;
    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++) {
            A[i][j] = (int)(xorshift(&s) & 0xff) - 128;
            B[i][j] = (int)(xorshift(&s) & 0xff) - 128;
        }

    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++) {
            int acc = 0;
            for (int k = 0; k < N; k++)
                acc += A[i][k] * B[k][j];
            C[i][j] = acc;
        }

    unsigned chk = 0;
    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++)
            chk = ((chk << 1) | (chk >> 31)) ^ (unsigned)C[i][j];

    return chk == EXPECTED ? 0 : 1;
}
