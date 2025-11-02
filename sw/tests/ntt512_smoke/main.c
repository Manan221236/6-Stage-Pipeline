#include <stdint.h>
#include "ntt512.h"

volatile uint64_t sink_poly512[512];

static uint64_t seed = 1;
static inline uint32_t lcg32(void){ seed = seed*1664525u + 1013904223u; return (uint32_t)seed; }

int main(void){
  const uint32_t q = 8380417u;
  uint64_t a[512];
  for(int i=0;i<512;++i) a[i] = lcg32() % q;
  ntt512_dil_u64(a);
  for(int i=0;i<512;++i) sink_poly512[i] = a[i];
  for(;;) {}
  return 0;
}
