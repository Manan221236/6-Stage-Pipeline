#include <stdint.h>
#include "k2red.h"

#ifndef VEC_COUNT
#define VEC_COUNT 2000
#endif

/* globals to inspect after run */
volatile uint32_t verify_mismatches;
volatile uint32_t verify_first_a, verify_first_b;
volatile uint32_t verify_ref, verify_dut;

/* simple LCG (deterministic, no libc) */
static inline uint32_t lcg32(uint32_t *s) {
  /* parameters from Numerical Recipes (ok for testing) */
  *s = (*s * 1664525u + 1013904223u);
  return *s;
}

/* reference (a*b) % q using 128-bit arithmetic */
static inline uint32_t ref_modmul_dil(uint32_t a, uint32_t b) {
  const uint64_t q = 8380417ull;
  __uint128_t p = (__uint128_t)a * (__uint128_t)b;
  uint64_t r = (uint64_t)(p % q);
  return (uint32_t)r;
}

int main(void) {
  uint32_t s = 1u; /* seed */
  uint32_t mism = 0;
  verify_first_a = verify_first_b = verify_ref = verify_dut = 0;

  for (int i = 0; i < VEC_COUNT; ++i) {
    uint32_t a = lcg32(&s) % 8380417u; /* keep in [0,q) */
    uint32_t b = lcg32(&s) % 8380417u;

    uint32_t r1 = ref_modmul_dil(a, b);
    uint32_t r2 = k2red64_dilithium(a, b);

    if (r1 != r2) {
      if (mism == 0) {
        verify_first_a = a;
        verify_first_b = b;
        verify_ref     = r1;
        verify_dut     = r2;
      }
      mism++;
    }
  }

  verify_mismatches = mism;

  for(;;) { } /* halt */
  return 0;
}
