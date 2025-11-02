CC := gcc
CFLAGS := -O2 -Wall -Wextra -std=c11
all: gen_zetas
gen_zetas: gen_zetas.c
	$(CC) $(CFLAGS) $< -o $@
clean:
	rm -f gen_zetas
.PHONY: all clean
