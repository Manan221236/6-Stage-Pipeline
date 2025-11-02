#include <stdint.h>
#include "cycle.h"

volatile uint64_t sink_cycles;

int main(void) {
    timing_t t;
    volatile uint64_t acc = 0;

    timing_start(&t);
    for (int i = 0; i < 100000; ++i) {
        acc += (uint64_t)i * 3u + 1u;
    }
    timing_stop(&t);

    sink_cycles = timing_cycles(&t);
    (void)acc; /* keep compiler from optimizing loop away */

    /* end: spin forever */
    for(;;) { }
    return 0;
}
