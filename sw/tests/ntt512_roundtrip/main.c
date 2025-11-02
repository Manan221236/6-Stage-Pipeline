#include <stdint.h>
#include "ntt512.h"

volatile uint32_t rt512_mismatches, rt512_first_idx, rt512_a, rt512_b;

static uint64_t seed=1;
static inline uint32_t lcg32(void){ seed=seed*1664525u+1013904223u; return (uint32_t)seed; }

int main(void){
  const uint32_t q=8380417u;
  uint64_t in[512], a[512];
  for(int i=0;i<512;++i){ in[i]=lcg32()%q; a[i]=in[i]; }
  ntt512_dil_u64(a);
  intt512_dil_u64(a);
  uint32_t mism=0; rt512_first_idx=0xFFFFFFFFu; rt512_a=rt512_b=0;
  for(int i=0;i<512;++i){
    uint32_t ai=(uint32_t)a[i]; if(ai>=q) ai-=q;
    uint32_t bi=(uint32_t)in[i]; if(bi>=q) bi-=q;
    if(ai!=bi){ if(!mism){ rt512_first_idx=i; rt512_a=ai; rt512_b=bi; } ++mism; }
  }
  rt512_mismatches=mism;
  for(;;){} return 0;
}
