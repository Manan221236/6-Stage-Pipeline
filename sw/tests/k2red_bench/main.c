#include <stdint.h>
#include "cycle.h"
#include "k2red.h"

/* results written to known addresses (inspect via debugger or mem) */
volatile uint64_t bench_cycles_total;
volatile uint64_t bench_cycles_per_op_x1000;
volatile uint32_t bench_sink_acc;

#ifndef K2RED_ITER
#define K2RED_ITER 200000
#endif

int main(void) {
  const uint32_t q = 8380417u, k = 1023u, m = 13u;
  const uint64_t A = 12345u, B = 6789u;

  timing_t t;
  volatile uint32_t acc = 0;

  timing_start(&t);
  for (int i = 0; i < K2RED_ITER; ++i) {
    /* core only: this is what we’ll schedule/tune later */
    uint64_t r = k2red64_core(A, B, q, k, m);
    acc ^= (uint32_t)r;
  }
  timing_stop(&t);

  uint64_t cyc = timing_cycles(&t);
  bench_cycles_total = cyc;
  bench_sink_acc = acc;

  /* fixed-point: cycles per op * 1000 (avoid float) */
  bench_cycles_per_op_x1000 = (cyc * 1000ull) / (uint64_t)K2RED_ITER;

  for(;;) { }
  return 0;
}
