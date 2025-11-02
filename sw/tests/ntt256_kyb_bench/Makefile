RISCV_PREFIX ?= riscv64-unknown-elf
CC  := $(RISCV_PREFIX)-gcc
AS  := $(RISCV_PREFIX)-gcc
LD  := $(RISCV_PREFIX)-gcc
OBJDUMP := $(RISCV_PREFIX)-objdump

CFLAGS  := -O3 -Wall -Wextra -ffreestanding -fno-builtin -march=rv64im -mabi=lp64
LDFLAGS := -nostartfiles -nostdlib -Wl,-Tlink.ld -Wl,--gc-sections -Wl,-e,_start
LIBS    := -lgcc
INCLUDES:= -I../../lib -I../../ntt

SRCS := main.c crt0.S ../../ntt/ntt256_kyb.c
OBJS := $(patsubst %.S,%.o,$(patsubst %.c,%.o,$(SRCS)))

TARGET := ntt256_kyb_bench.elf

all: $(TARGET)

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

%.o: %.S
	$(AS) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(TARGET): $(OBJS) link.ld
	$(LD) $(CFLAGS) $(LDFLAGS) $(OBJS) $(LIBS) -o $@
	@echo
	@echo "---- objdump (symbols) ----"
	@$(OBJDUMP) -t $@ | egrep "bench_cycles_|bench_sink_acc" || true
	@echo "---- objdump (head) ----"
	@$(OBJDUMP) -d $@ | head -n 60
	@echo "------------------------"

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean
