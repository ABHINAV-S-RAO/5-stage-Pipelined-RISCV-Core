// Bitwise CRC-32 (IEEE, same as zlib) over 256 pseudo-random bytes.
// Tight loop with a data-dependent branch on every bit: hard to predict.
// Expected value computed offline with Python's zlib.crc32.
#define LEN 256
#define EXPECTED 0xc1d3d839u

static unsigned char buf[LEN];

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
    unsigned s = 0xdeadbeef;
    for (int i = 0; i < LEN; i++)
        buf[i] = (unsigned char)xorshift(&s);

    unsigned crc = 0xffffffffu;
    for (int i = 0; i < LEN; i++) {
        crc ^= buf[i];
        for (int b = 0; b < 8; b++) {
            if (crc & 1)
                crc = (crc >> 1) ^ 0xedb88320u;
            else
                crc >>= 1;
        }
    }
    crc = ~crc;

    return crc == EXPECTED ? 0 : 1;
}
