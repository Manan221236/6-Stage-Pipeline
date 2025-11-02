.PHONY: all hello clean

all: hello

hello:
	$(MAKE) -C sw/tests/hello_cycle

clean:
	$(MAKE) -C sw/tests/hello_cycle clean
