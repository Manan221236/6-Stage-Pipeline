#include <stdint.h>
#include "ntt256.h"

volatile uint64_t sink_poly[256];

static uint64_t seed = 1;
static inline uint32_t lcg32(void){ seed = seed*1664525u + 1013904223u; return (uint32_t)seed; }

int main(void){
  uint64_t a[256];
  /* init a with small residues < q to avoid accidental overflow before reduces */
  for(int i=0;i<256;++i) a[i] = (uint64_t)(lcg32() % 8380417u);
  ntt256_dil_u64(a);
  for(int i=0;i<256;++i) sink_poly[i] = a[i]; /* make visible */
  for(;;){}
  return 0;
}
