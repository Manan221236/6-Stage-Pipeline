.PHONY: all hello k2red clean

all: hello

hello:
	$(MAKE) -C sw/tests/hello_cycle

k2red:
	$(MAKE) -C sw/tests/k2red_smoke

clean:
	$(MAKE) -C sw/tests/hello_cycle clean
	$(MAKE) -C sw/tests/k2red_smoke clean
