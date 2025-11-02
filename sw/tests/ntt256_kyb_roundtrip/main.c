#include <stdint.h>
#include "ntt256_kyb.h"
volatile uint32_t kyb_rt_mismatches, kyb_rt_first_idx, kyb_rt_a, kyb_rt_b;
static uint64_t seed=1; static inline uint32_t lcg32(void){ seed=seed*1664525u+1013904223u; return (uint32_t)seed; }
int main(void){
  const uint32_t q=3329u; uint64_t in[256], a[256];
  for(int i=0;i<256;++i){ in[i]=lcg32()%q; a[i]=in[i]; }
  ntt256_kyb_u64(a); intt256_kyb_u64(a);
  uint32_t mism=0; kyb_rt_first_idx=0xFFFFFFFFu; kyb_rt_a=kyb_rt_b=0;
  for(int i=0;i<256;++i){
    uint32_t ai=(uint32_t)a[i]; if(ai>=q) ai-=q;
    uint32_t bi=(uint32_t)in[i]; if(bi>=q) bi-=q;
    if(ai!=bi){ if(!mism){ kyb_rt_first_idx=i; kyb_rt_a=ai; kyb_rt_b=bi; } ++mism; }
  }
  kyb_rt_mismatches=mism; for(;;){} return 0;
}
