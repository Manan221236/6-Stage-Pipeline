#include <stdint.h>
#include "k2red.h"
#include "zetas_dil_n256.h"   /* generated forward/inverse tables */

/* fold once by q (branchless): returns x - q if x >= q else x */
static inline uint64_t fold_q(uint64_t x, uint64_t q) {
  uint64_t diff = x - q;
  uint64_t mask = -(uint64_t)(x >= q);
  return (diff & mask) | (x & ~mask);
}

/* ---------- Forward NTT: Cooley–Tukey (DIT), Harvey butterflies ---------- */
void ntt256_dil_u64(uint64_t *a) {
  const uint32_t q = 8380417u;
  const uint32_t k = 1023u;
  const uint32_t m = 13u;

  int kidx = 1; /* if zetas[0]==1, many flows start at 1 */
  for (int len = 128; len >= 1; len >>= 1) {
    for (int start = 0; start < 256; start += (len << 1)) {
      uint64_t zeta = zetas_dil_fwd_n256[kidx++];
      for (int j = 0; j < len; ++j) {
        uint64_t u = a[start + j];
        uint64_t v = a[start + j + len];

        /* t = zeta * v (mod q) via K²RED core + correction to [0,q) */
        uint64_t t = k2red64_core(zeta, v, q, k, m);
        t = k2red64_reduce_q(t, q);

        /* x = u + t in [0, 2q) with two folds */
        uint64_t x = u + t;
        x = fold_q(x, q);
        x = fold_q(x, q);
        a[start + j] = x;

        /* y = u + q - t in [0, 2q) with two folds */
        uint64_t y = u + q - t;
        y = fold_q(y, q);
        y = fold_q(y, q);
        a[start + j + len] = y;
      }
    }
  }
}

/* ---------- Inverse NTT: Gentleman–Sande (GS), Harvey butterflies ---------- */
/* Uses inverse twiddles and multiplies by N^{-1} at the end. */
void intt256_dil_u64(uint64_t *a) {
  const uint32_t q = 8380417u;
  const uint32_t k = 1023u;
  const uint32_t m = 13u;

  int kidx = 1; /* zetas_dil_inv_n256[0] == 1; advance similarly */
  for (int len = 1; len <= 128; len <<= 1) {
    for (int start = 0; start < 256; start += (len << 1)) {
      uint64_t zeta = zetas_dil_inv_n256[kidx++];
      for (int j = 0; j < len; ++j) {
        uint64_t u = a[start + j];
        uint64_t v = a[start + j + len];

        /* in GS, we reconstruct original pair:
           t = u + v  (mod 2q),  r = u + q - v  (mod 2q)
           then a[start+j] = t
                a[start+j+len] = zeta * r (mod q)
         */
        uint64_t t = u + v;
        t = fold_q(t, q);
        t = fold_q(t, q);

        uint64_t r = u + q - v;
        r = fold_q(r, q);
        r = fold_q(r, q);

        uint64_t w = k2red64_core(zeta, r, q, k, m);
        w = k2red64_reduce_q(w, q);

        a[start + j]       = t;
        a[start + j + len] = w;
      }
    }
  }

  /* final scaling by N^{-1} mod q */
  const uint64_t ninv = zetas_dil_ninv_n256; /* generated constant */
  for (int i = 0; i < 256; ++i) {
    uint64_t x = k2red64_core(a[i], ninv, q, k, m);
    a[i] = k2red64_reduce_q(x, q);
  }
}
