# Firmware layout (RV64, processor-only kernels)

- sw/lib         : low-level arithmetic (K²RED, Montgomery, Barrett), utils
- sw/ntt         : NTT / iNTT / pointwise kernels (N=512) for Kyber & Dilithium
- sw/kyber       : Kyber inner-loop harness (NTT(a), NTT(b), pointwise, iNTT)
- sw/dilithium   : Dilithium inner-loop harness
- sw/tests       : unit tests, random regression, cycle/energy benchmarks

Build system will target riscv64-unknown-elf (bare metal).
