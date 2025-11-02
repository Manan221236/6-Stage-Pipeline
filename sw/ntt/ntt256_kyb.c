#include <stdint.h>
#include "k2red.h"
#include "zetas_kyb_n256.h"

static inline uint64_t fold_q(uint64_t x, uint64_t q) {
  uint64_t diff = x - q;
  uint64_t mask = -(uint64_t)(x >= q);
  return (diff & mask) | (x & ~mask);
}

/* Forward NTT: DIT, Harvey, in-place (Kyber: q=3329) */
void ntt256_kyb_u64(uint64_t *a) {
  const uint32_t q = 3329u;
  const uint32_t k = 13u;   /* for q = 13*2^8 + 1 */
  const uint32_t m = 8u;

  int z = 1; /* skip index 0 if it is 1 */
  for (int len = 128; len >= 1; len >>= 1) {
    for (int start = 0; start < 256; start += (len << 1)) {
      uint64_t zeta = zetas_kyb_fwd_n256[z++];
      for (int j = 0; j < len; ++j) {
        uint64_t u = a[start + j];
        uint64_t v = a[start + j + len];

        uint64_t t = k2red64_core(zeta, v, q, k, m);
        t = k2red64_reduce_q(t, q);

        uint64_t x = u + t;      x = fold_q(x, q); x = fold_q(x, q);
        uint64_t y = u + q - t;  y = fold_q(y, q); y = fold_q(y, q);

        a[start + j]       = x;
        a[start + j + len] = y;
      }
    }
  }
}

/* Inverse NTT: GS, Harvey, in-place + multiply by N^{-1} */
void intt256_kyb_u64(uint64_t *a) {
  const uint32_t q = 3329u;
  const uint32_t k = 13u;
  const uint32_t m = 8u;

  int z = 1;
  for (int len = 1; len <= 128; len <<= 1) {
    for (int start = 0; start < 256; start += (len << 1)) {
      uint64_t zeta = zetas_kyb_inv_n256[z++];
      for (int j = 0; j < len; ++j) {
        uint64_t u = a[start + j];
        uint64_t v = a[start + j + len];

        uint64_t t = u + v;      t = fold_q(t, q); t = fold_q(t, q);
        uint64_t r = u + q - v;  r = fold_q(r, q); r = fold_q(r, q);

        uint64_t w = k2red64_core(zeta, r, q, k, m);
        w = k2red64_reduce_q(w, q);

        a[start + j]       = t;
        a[start + j + len] = w;
      }
    }
  }

  const uint64_t ninv = zetas_kyb_ninv_n256;
  for (int i = 0; i < 256; ++i) {
    uint64_t x = k2red64_core(a[i], ninv, q, k, m);
    a[i] = k2red64_reduce_q(x, q);
  }
}
