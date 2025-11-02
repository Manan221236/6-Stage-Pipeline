.PHONY: all hello k2red k2red_bench k2red_verify clean

all: hello

hello:
	$(MAKE) -C sw/tests/hello_cycle

k2red:
	$(MAKE) -C sw/tests/k2red_smoke

k2red_bench:
	$(MAKE) -C sw/tests/k2red_bench

k2red_verify:
	$(MAKE) -C sw/tests/k2red_verify

clean:
	$(MAKE) -C sw/tests/hello_cycle clean
	$(MAKE) -C sw/tests/k2red_smoke clean
	$(MAKE) -C sw/tests/k2red_bench clean
	$(MAKE) -C sw/tests/k2red_verify clean
