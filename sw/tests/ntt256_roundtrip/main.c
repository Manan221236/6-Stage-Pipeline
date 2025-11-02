#include <stdint.h>
#include "ntt256.h"

/* report */
volatile uint32_t rt_mismatches;
volatile uint32_t rt_first_idx;
volatile uint32_t rt_a, rt_b;

static uint64_t seed = 1;
static inline uint32_t lcg32(void){ seed = seed*1664525u + 1013904223u; return (uint32_t)seed; }

int main(void){
  const uint32_t q = 8380417u;
  uint64_t in[256], a[256];

  for(int i=0;i<256;++i){
    in[i] = (uint64_t)(lcg32() % q);
    a[i] = in[i];
  }

  ntt256_dil_u64(a);
  intt256_dil_u64(a);

  uint32_t mism = 0;
  rt_first_idx = 0xFFFFFFFFu;
  rt_a = rt_b = 0;

  for(int i=0;i<256;++i){
    uint32_t ai = (uint32_t)a[i];
    uint32_t bi = (uint32_t)in[i];
    /* Values should be canonical [0,q); if not, fold once */
    if (ai >= q) ai -= q;
    if (bi >= q) bi -= q;
    if (ai != bi) {
      if (mism == 0) {
        rt_first_idx = (uint32_t)i;
        rt_a = ai;
        rt_b = bi;
      }
      ++mism;
    }
  }
  rt_mismatches = mism;

  for(;;){}
  return 0;
}
