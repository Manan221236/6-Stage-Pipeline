#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <stdlib.h>

static uint64_t modmul(uint64_t a, uint64_t b, uint64_t q) {
    __uint128_t p = ( __uint128_t)a * b;
    return (uint64_t)(p % q);
}
static uint64_t modpow(uint64_t a, uint64_t e, uint64_t q) {
    uint64_t r = 1 % q;
    while (e) {
        if (e & 1) r = modmul(r, a, q);
        a = modmul(a, a, q);
        e >>= 1;
    }
    return r;
}
static uint64_t modinv(uint64_t a, uint64_t q) {
    // Fermat: a^(q-2) mod q (q must be prime)
    return modpow(a, q - 2, q);
}

int main(int argc, char **argv) {
    if (argc < 5) {
        fprintf(stderr, "Usage: %s <q> <N> <primitive_root_w> <out_prefix>\n", argv[0]);
        fprintf(stderr, "Example: %s 8380417 512 1753 dil\n", argv[0]);
        return 1;
    }
    uint64_t q = strtoull(argv[1], NULL, 0);
    int N = atoi(argv[2]);
    uint64_t w = strtoull(argv[3], NULL, 0);
    const char* prefix = argv[4];

    if (N <= 1 || (N & (N-1)) != 0) {
        fprintf(stderr, "N must be a power of two.\n");
        return 2;
    }

    // Verify w is an N-th primitive root: w^N == 1 (mod q) and w^(N/2) != 1
    uint64_t wn = modpow(w, N, q);
    uint64_t wn2 = modpow(w, N/2, q);
    if (wn != 1 % q || wn2 == 1 % q) {
        fprintf(stderr, "Warning: provided w does NOT look like a primitive %d-th root mod %" PRIu64 ". Proceeding anyway.\n", N, q);
    }

    // Forward twiddles (DIT): zetas[k] = w^(bitrev(k)) or stage-ordered?
    // For simplicity: produce a flat table of powers w^0..w^(N-1), and we will index per stage in code.
    // Also emit inverse twiddles using w_inv = w^{-1}.
    uint64_t w_inv = modinv(w, q);

    char hname[256];
    snprintf(hname, sizeof(hname), "sw/ntt/zetas_%s_n%d.h", prefix, N);
    FILE* f = fopen(hname, "w");
    if (!f) { perror("fopen"); return 3; }

    fprintf(f, "#ifndef ZETAS_%s_N%d_H\n#define ZETAS_%s_N%d_H\n\n", prefix, N, prefix, N);
    fprintf(f, "#include <stdint.h>\n\n");
    fprintf(f, "/* Auto-generated: q=%" PRIu64 ", N=%d, w=%" PRIu64 " */\n", q, N, w);

    // forward
    fprintf(f, "static const uint32_t zetas_%s_fwd_n%d[%d] = {\n  ", prefix, N, N);
    uint64_t cur = 1 % q;
    for (int i = 0; i < N; ++i) {
        fprintf(f, "%s%u", (i? ", " : ""), (unsigned)cur);
        cur = modmul(cur, w, q);
        if ((i+1) % 16 == 0 && i+1 < N) fprintf(f, ",\n  ");
    }
    fprintf(f, "\n};\n\n");

    // inverse
    fprintf(f, "static const uint32_t zetas_%s_inv_n%d[%d] = {\n  ", prefix, N, N);
    cur = 1 % q;
    for (int i = 0; i < N; ++i) {
        fprintf(f, "%s%u", (i? ", " : ""), (unsigned)cur);
        cur = modmul(cur, w_inv, q);
        if ((i+1) % 16 == 0 && i+1 < N) fprintf(f, ",\n  ");
    }
    fprintf(f, "\n};\n\n");

    // modular inverse of N (for iNTT scaling)
    uint64_t ninv = modinv((uint64_t)N, q);
    fprintf(f, "static const uint32_t zetas_%s_ninv_n%d = %u;\n\n", prefix, N, (unsigned)ninv);

    fprintf(f, "#endif\n");
    fclose(f);

    fprintf(stdout, "Wrote %s\n", hname);
    return 0;
}
