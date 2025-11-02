#include <stdint.h>
#include "cycle.h"
#include "k2red.h"

/* sinks so linker keeps results; useful when we JTAG-inspect memory */
volatile uint32_t sink_out[8];
volatile uint64_t sink_cycles;

int main(void) {
    /* a few deterministic test vectors */
    const uint32_t a[] = {1, 12345, 8380416, 1023, 0xABCDEu & 0x7FFFFFu};
    const uint32_t b[] = {2, 6789,   1234,   777,  0x13579u & 0x7FFFFFu};

    /* functional checks (store results) */
    for (int i = 0; i < 5; ++i) {
        sink_out[i] = k2red64_dilithium(a[i], b[i]);
    }

    /* micro-bench: repeat one multiply many times to get stable cycles */
    timing_t t;
    volatile uint32_t acc = 0;
    const uint32_t A = 12345u, B = 6789u;

    timing_start(&t);
    for (int it = 0; it < 200000; ++it) {
        acc ^= k2red64_dilithium(A, B);
    }
    timing_stop(&t);

    sink_out[5] = acc;
    sink_cycles = timing_cycles(&t);

    for(;;) { } /* halt */
    return 0;
}
