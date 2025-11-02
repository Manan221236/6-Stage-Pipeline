#ifndef K2RED_H
#define K2RED_H

#include <stdint.h>
#include "cycle.h"

/* Notes:
 * - RV64IM required (mul/mulhu). Zba/Zbb allowed but not required.
 * - This implements double KRED:
 *     R  = A*B
 *     Rl = low m bits of R
 *     Rh = R >> m  (across 128-bit product)
 *     C  = k*Rl - Rh
 *     Cl = low m bits of C
 *     Ch = C >> m
 *     C' = k*Cl - Ch
 * - For Dilithium: q=8380417, k=1023, m=13 (mask=0x1FFF).
 */

/* Combine 64x64->128 multiply via RV64 mul/mulhu. */
static inline void mul128_u64(uint64_t a, uint64_t b, uint64_t *hi, uint64_t *lo) {
  uint64_t hlo, hhi;
  __asm__ volatile(
      "mul  %0, %2, %3\n\t"
      "mulhu %1, %2, %3\n\t"
      : "=&r"(hlo), "=&r"(hhi)
      : "r"(a), "r"(b));
  *lo = hlo;
  *hi = hhi;
}

/* Single logical right shift of a 128-bit {hi:lo} pair by m (0<m<64). */
static inline uint64_t shr128_u64(uint64_t hi, uint64_t lo, uint32_t m) {
  /* (lo >> m) | (hi << (64 - m)) */
  return (lo >> m) | (hi << (64 - m));
}

/* Branchless conditional subtract: returns x - q if x >= q, else x. */
static inline uint64_t sub_if_ge(uint64_t x, uint64_t q) {
  uint64_t diff = x - q;
  /* mask = all-ones if x >= q, else 0 */
  uint64_t mask = -(uint64_t)(x >= q);
  return (diff & mask) | (x & ~mask);
}

/* K²RED core WITHOUT final mod-q correction (for lazy reduction inside NTT).
 * Returns a value typically in a small multiple range of q.
 */
static inline uint64_t k2red64_core(uint64_t a, uint64_t b,
                                    uint32_t q, uint32_t k, uint32_t m) {
  /* 1) R = a*b (128-bit) */
  uint64_t hi, lo;
  mul128_u64(a, b, &hi, &lo);

  /* mask = (1<<m)-1 */
  const uint64_t mask = (m == 64) ? ~0ull : ((1ull << m) - 1ull);

  /* 2) split R */
  uint64_t Rl = lo & mask;
  uint64_t Rh = (m ? shr128_u64(hi, lo, m) : hi); /* m>0 in our use */

  /* 3) C = k*Rl - Rh  (fits in 64b for Dilithium params) */
  uint64_t C = k * Rl;
  C -= Rh;

  /* 4) split C */
  uint64_t Cl = C & mask;
  uint64_t Ch = (m ? (C >> m) : 0ull); /* logical is fine for our ranges */

  /* 5) C' = k*Cl - Ch */
  uint64_t Cp = k * Cl;
  Cp -= Ch;

  return Cp;
}

/* Optional final correction into [0, q). Use when you need canonical residues. */
static inline uint64_t k2red64_reduce_q(uint64_t x, uint32_t q) {
  /* First fold into [0,2q) by adding q if negative in signed sense (avoid branches). */
  /* In our unsigned flow x is already non-negative, so we can directly reduce by q twice. */
  x = sub_if_ge(x, q);
  x = sub_if_ge(x, q); /* at most 2*q window */
  return x;
}

/* Dilithium-specialized convenience wrapper (q=8380417, k=1023, m=13). */
static inline uint32_t k2red64_dilithium(uint32_t a, uint32_t b) {
  const uint32_t q = 8380417u;
  const uint32_t k = 1023u;
  const uint32_t m = 13u;
  uint64_t r = k2red64_core((uint64_t)a, (uint64_t)b, q, k, m);
  r = k2red64_reduce_q(r, q);
  return (uint32_t)r;
}

#endif /* K2RED_H */
