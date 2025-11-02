#ifndef CYCLE_H
#define CYCLE_H

#include <stdint.h>

/* RV64 cycle counters (works on bare-metal or simple SoCs) */
static inline uint64_t rdcycle(void) {
  uint64_t x;
  __asm__ volatile ("rdcycle %0" : "=r"(x));
  return x;
}

static inline uint64_t rdtime(void) {
  uint64_t x;
  __asm__ volatile ("rdtime %0" : "=r"(x));
  return x;
}

static inline uint64_t rdinstret(void) {
  uint64_t x;
  __asm__ volatile ("rdinstret %0" : "=r"(x));
  return x;
}

/* Convenience timing scope */
typedef struct {
  uint64_t start_cycle;
  uint64_t end_cycle;
} timing_t;

static inline void timing_start(timing_t *t) {
  __asm__ volatile ("" ::: "memory");
  t->start_cycle = rdcycle();
}

static inline void timing_stop(timing_t *t) {
  t->end_cycle = rdcycle();
  __asm__ volatile ("" ::: "memory");
}

static inline uint64_t timing_cycles(const timing_t *t) {
  return t->end_cycle - t->start_cycle;
}

#endif /* CYCLE_H */
