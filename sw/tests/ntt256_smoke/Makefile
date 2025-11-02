RISCV_PREFIX ?= riscv64-unknown-elf
CC  := $(RISCV_PREFIX)-gcc
AS  := $(RISCV_PREFIX)-gcc
LD  := $(RISCV_PREFIX)-gcc
OBJDUMP := $(RISCV_PREFIX)-objdump

CFLAGS := -O3 -Wall -Wextra -ffreestanding -fno-builtin -march=rv64im -mabi=lp64
LDFLAGS := -nostartfiles -nostdlib -Wl,-Tlink.ld -Wl,--gc-sections -Wl,-e,_start
LIBS := -lgcc
INCLUDES := -I../../lib -I../../ntt

SRCS := main.c crt0.S ../../ntt/ntt256.c
OBJS := $(SRCS:.c=.o)
OBJS := $(OBJS:.S=.o)

TARGET := ntt256_smoke.elf

all: $(TARGET)

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

%.o: %.S
	$(AS) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(TARGET): $(OBJS) link.ld
	$(LD) $(CFLAGS) $(LDFLAGS) $(OBJS) $(LIBS) -o $@
	@echo
	@echo "---- objdump (head) ----"
	@$(OBJDUMP) -d $@ | head -n 60
	@echo "------------------------"

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean
