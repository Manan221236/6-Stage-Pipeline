#include <stdint.h>
#include "ntt256_kyb.h"
volatile uint64_t sink_poly_kyb256[256];
static uint64_t seed=1; static inline uint32_t lcg32(void){ seed=seed*1664525u+1013904223u; return (uint32_t)seed; }
int main(void){
  const uint32_t q=3329u; uint64_t a[256];
  for(int i=0;i<256;++i) a[i]=lcg32()%q;
  ntt256_kyb_u64(a);
  for(int i=0;i<256;++i) sink_poly_kyb256[i]=a[i];
  for(;;){} return 0;
}
