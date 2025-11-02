#ifndef NTT256_H
#define NTT256_H
#include <stdint.h>

/* Forward NTT (DIT, in-place), Dilithium q=8380417 */
void ntt256_dil_u64(uint64_t *coeffs);

/* Inverse NTT (GS, in-place), Dilithium q=8380417 */
void intt256_dil_u64(uint64_t *coeffs);

#endif
