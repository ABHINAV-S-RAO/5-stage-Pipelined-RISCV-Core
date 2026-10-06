// Recursive quicksort of 400 pseudo-random ints. Branch-heavy and data
// dependent. Self-checking: result must be sorted and keep the same sum/xor.
#define N 400

static int a[N];

static unsigned xorshift(unsigned *s)
{
    unsigned x = *s;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    return *s = x;
}

static void quicksort(int *v, int lo, int hi)
{
    while (lo < hi) {
        int p = v[(lo + hi) >> 1];
        int i = lo, j = hi;
        while (i <= j) {
            while (v[i] < p) i++;
            while (v[j] > p) j--;
            if (i <= j) {
                int t = v[i]; v[i] = v[j]; v[j] = t;
                i++; j--;
            }
        }
        // recurse into the smaller half, loop on the larger
        if (j - lo < hi - i) { quicksort(v, lo, j); lo = i; }
        else                 { quicksort(v, i, hi); hi = j; }
    }
}

int main(void)
{
    unsigned s = 0xcafef00d;
    unsigned sum = 0, xr = 0;
    for (int i = 0; i < N; i++) {
        a[i] = (int)xorshift(&s);
        sum += a[i];
        xr ^= a[i];
    }

    quicksort(a, 0, N - 1);

    unsigned sum2 = a[0], xr2 = a[0];
    for (int i = 1; i < N; i++) {
        if (a[i - 1] > a[i]) return 1;
        sum2 += a[i];
        xr2 ^= a[i];
    }
    if (sum2 != sum) return 2;
    if (xr2 != xr)   return 3;
    return 0;
}
