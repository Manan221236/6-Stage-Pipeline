.PHONY: all hello k2red k2red_bench k2red_verify ntt256 ntt256_rt clean

all: hello

hello:
	$(MAKE) -C sw/tests/hello_cycle

k2red:
	$(MAKE) -C sw/tests/k2red_smoke

k2red_bench:
	$(MAKE) -C sw/tests/k2red_bench

k2red_verify:
	$(MAKE) -C sw/tests/k2red_verify

ntt256:
	$(MAKE) -C sw/tests/ntt256_smoke

ntt256_rt:
	$(MAKE) -C sw/tests/ntt256_roundtrip

clean:
	$(MAKE) -C sw/tests/hello_cycle clean
	$(MAKE) -C sw/tests/k2red_smoke clean
	$(MAKE) -C sw/tests/k2red_bench clean
	$(MAKE) -C sw/tests/k2red_verify clean
	$(MAKE) -C sw/tests/ntt256_smoke clean
	$(MAKE) -C sw/tests/ntt256_roundtrip clean
