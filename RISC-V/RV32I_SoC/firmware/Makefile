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

app-led0:
	$(MAKE) APP=led0_blink all

app-ping:
	$(MAKE) APP=ping_pong all

uart-upload:
	$(MAKE) APP=$(APP) clean all
	python3 upload_uart_boot.py --port "$(PORT)" --baud "$(BAUD)" --bin "$(BIN)" --entry 0 --repeat "$(REPEAT)"

uart-upload-reset:
	$(MAKE) APP=$(APP) clean all
	python3 upload_uart_boot.py --port "$(PORT)" --baud "$(BAUD)" --bin "$(BIN)" --entry 0 --repeat 40 --interval 0.05

uart-upload-raw:
	$(MAKE) APP=$(APP) clean all
	python3 upload_uart_boot.py --raw --port "$(PORT)" --baud "$(BAUD)" --bin "$(BIN)" --repeat 1 --pre-delay 2.0 --post-delay 0.2

clean:
	rm -f $(ELF) $(BIN) $(DUMP) $(LOCAL_HEX)

.PHONY: all clean image list-apps app-led app-led0 app-ping uart-upload uart-upload-reset

# GCC-only workflow (no UART upload):
# 1) Build firmware image with GCC
# 2) Rebuild/program FPGA bitstream so CPU boots that image
gcc-build:
	$(MAKE) APP=$(APP) clean all

fpga-program:
	cd .. && FIRMWARE_APP=$(APP) ./flows/04_numato_mimas_a7/scripts/run_prjxray_numato_ppa.sh
	cd .. && openFPGALoader -b mimas_a7 flows/04_numato_mimas_a7/build/top.bit

fpga-program-flash:
	cd .. && FIRMWARE_APP=$(APP) ./flows/04_numato_mimas_a7/scripts/run_prjxray_numato_ppa.sh
	cd .. && openFPGALoader -b mimas_a7 -f flows/04_numato_mimas_a7/build/top.bit

run-gcc-only: fpga-program-flash

.PHONY: gcc-build fpga-program fpga-program-flash run-gcc-only

# Preferred workflow:
# 1) Program core once (bitstream with UART boot + heartbeat on LED7)
# 2) Upload only firmware over UART for each C code change
program-core-once:
	cd .. && FIRMWARE_APP=$(APP) ./flows/04_numato_mimas_a7/scripts/run_prjxray_numato_ppa.sh
	cd .. && openFPGALoader -b mimas_a7 -f flows/04_numato_mimas_a7/build/top.bit

firmware-only-upload: uart-upload-raw

.PHONY: program-core-once firmware-only-upload uart-upload-raw
