CROSS ?= riscv64-unknown-elf
CC := $(CROSS)-gcc
OBJCOPY := $(CROSS)-objcopy
OBJDUMP := $(CROSS)-objdump

CFLAGS := -march=rv32i -mabi=ilp32 -Os -ffreestanding -nostdlib -nostartfiles -Wall -Wextra
LDFLAGS := -T link.ld -nostdlib -Wl,--gc-sections

APP ?= ping_pong
PORT ?= /dev/ttyUSB0
BAUD ?= 115200
REPEAT ?= 1

TARGET := firmware
BIN := $(TARGET).bin
ELF := $(TARGET).elf
DUMP := $(TARGET).dump
LOCAL_HEX := bootrom.hex
ROOT_HEX := ../bootrom.hex
INIT_WORDS ?= 128

all: $(ROOT_HEX)

$(ELF): crt0.S $(APP).c link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ crt0.S $(APP).c

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

$(DUMP): $(ELF)
	$(OBJDUMP) -d $< > $@

$(LOCAL_HEX): $(BIN)
	@od -An -tx1 -v $< | \
	awk '{ for (i = 1; i <= NF; i += 4) { if ((i + 3) <= NF) printf "%s%s%s%s\n", $$(i+3), $$(i+2), $$(i+1), $$i; } }' > $@
	@lines=$$(wc -l < $@); \
	while [ $$lines -lt $(INIT_WORDS) ]; do echo 00000013 >> $@; lines=$$((lines + 1)); done

$(ROOT_HEX): $(LOCAL_HEX)
	cp -f $(LOCAL_HEX) $(ROOT_HEX)

image: $(ROOT_HEX)

list-apps:
	@echo "Available firmware apps:"
	@ls -1 *.c | sed 's/\.c$$//' | sed 's/^/  - /'

app-led:
	$(MAKE) APP=led_showcase all

app-ping:
	$(MAKE) APP=ping_pong all

uart-upload:
	$(MAKE) APP=$(APP) clean all
	python3 upload_uart_boot.py --port "$(PORT)" --baud "$(BAUD)" --bin "$(BIN)" --entry 0 --repeat "$(REPEAT)"

uart-upload-reset:
	$(MAKE) APP=$(APP) clean all
	python3 upload_uart_boot.py --port "$(PORT)" --baud "$(BAUD)" --bin "$(BIN)" --entry 0 --repeat 40 --interval 0.05

clean:
	rm -f $(ELF) $(BIN) $(DUMP) $(LOCAL_HEX)

.PHONY: all clean image list-apps app-led app-ping uart-upload uart-upload-reset
