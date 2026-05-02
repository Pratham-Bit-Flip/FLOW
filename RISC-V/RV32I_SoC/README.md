# RV32I RISC-V SoC

A complete open-source **32-bit RISC-V (RV32I) soft processor** written in Verilog, targeting the **Numato Mimas A7 (Artix-7 XC7A50T)**. Synthesized and verified on real hardware using an entirely open-source toolchain.

> **Part of the FLOW project** — see the [root README](../../README.md) for the full pipeline overview.

---

## Status

| Component | Status |
|---|---|
| RV32I core (hardcoded firmware path) | ✅ Working on hardware |
| Bitstream generation (open-source flow) | ✅ Working |
| Unit + integration simulation | ✅ All testbenches passing |
| UART bootloader (firmware-over-serial) | ⚠️ UART activity detected, upload under debug |
| MMIO LED control | ✅ Working |
| Hardware heartbeat (LED7) | ✅ Working |

---

## Quick Start

### Flash the bitstream (one-time)

```bash
cd flows/04_numato_mimas_a7/scripts
FIRMWARE_APP=ping_pong ./run_prjxray_numato_ppa.sh
openFPGALoader -b mimas_a7 -f ../build/top.bit
```

After programming, LEDs cycle `0x01 → 0x02 → 0x04 → 0x08` — that pattern confirms the CPU is executing firmware.

### UART firmware upload (when bootloader is stable)

```bash
cd firmware
make APP=ping_pong uart-upload PORT=/dev/ttyUSB0 BAUD=115200
```

This path is present and partially working — UART activity is detected, but reliable firmware handoff is still being debugged.

---

## Project Structure

```
RV32I_SoC/
├── Makefile                 ← drives all testbenches
├── rtl/
│   ├── core/                ← ALU, decoder, datapath, PC, regfile, write-back
│   ├── memory/              ← instruction/data/flash memories, memory map
│   ├── peripherals/         ← UART TX/RX, MMIO, bootloader
│   └── top/                 ← SoC and board wrappers
├── tb/
│   ├── unit/                ← module-level testbenches
│   └── integration/         ← top-level CPU and SoC testbenches
├── firmware/                ← bare-metal C apps, startup, linker, UART uploader
├── init/                    ← bootrom.hex / flash.hex (initial memory contents)
├── flows/                   ← per-board FPGA build flows (04_numato_mimas_a7 is active)
├── scripts/                 ← run_sim.sh, run_all_tests.sh, build_rv32i.sh
├── docs/                    ← bootloader protocol, memory map, simulation notes
├── artifacts/               ← generated JSON, SVG, reports, sim builds
└── legacy/                  ← unused / experimental modules
```

---

## Architecture

### CPU Core

- **Pipeline:** 5-stage (Fetch → Decode → Execute → Memory → WriteBack)
- **ISA:** RV32I base integer instruction set
- **Memory:** 4 KB instruction RAM + 4 KB data RAM
- **Registers:** 32×32-bit (x0–x31, x0 hardwired to 0)
- **ALU:** ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
- **Branches:** BEQ, BNE, BLT, BGE, BLTU, BGEU

### Peripherals

| Peripheral | Address | Notes |
|---|---|---|
| MMIO LED | `0x20000000` | 8-bit output, firmware-controlled |
| UART MMIO | `0x80000000` | 115200 baud, TX/RX |
| UART Bootloader | — | Firmware upload path (under debug) |

### Board I/O (Numato Mimas A7)

| Signal | FPGA Pin | Notes |
|---|---|---|
| UART_RX | J21 (B4) | Receives from CH340 TX |
| UART_TX | K22 (B5) | Sends to CH340 RX |
| LED[7] | — | Hardware heartbeat (~1 Hz, no firmware needed) |
| LED[6] | — | UART RX activity indicator |
| LED[5:0] | — | Firmware MMIO (C code controlled) |
| Clock | — | 100 MHz on-board oscillator |
| Reset | — | Active-low button |

---

## Build System

### Prerequisites

```bash
# Firmware cross-compiler
riscv64-unknown-elf-gcc   # v13.2.0

# FPGA toolchain (stored under ../../tools/, no system install needed)
yosys
nextpnr-xilinx
openFPGALoader

# Scripting / UART upload
python3
pyserial
```

### Firmware

```bash
cd firmware

make APP=ping_pong                   # build firmware.bin only
make APP=ping_pong uart-upload       # build + upload (single attempt)
make APP=ping_pong uart-upload-reset # build + upload (40 attempts, more robust)
make list-apps                       # show all available .c apps
```

### FPGA Bitstream

```bash
cd flows/04_numato_mimas_a7/scripts
FIRMWARE_APP=ping_pong ./run_prjxray_numato_ppa.sh
# Output: ../build/top.bit
```

---

## Simulation & Testing

### Run testbenches

```bash
# From RV32I_SoC root:
make all                 # run every testbench
make alu_tb              # ALU unit test
make decoder_tb          # instruction decoder
make immgen_tb           # immediate generator
make pc_tb               # program counter
make reg_file_tb         # register file
make data_mem_tb         # data memory
make branch_comp_tb      # branch comparator
make wb_mux_tb           # write-back mux
make test_bootrom_tb     # boot ROM
make riscv_top_tb        # full CPU integration
make riscv_integration_tb # SoC integration
make rv32i_led_top_tb    # board wrapper
```

### What’s covered

| Module | Status |
|---|---|
| ALU | ✅ All 10 RV32I operations |
| Decoder | ✅ All formats (R, I, S, B, U, J) |
| Immediate Generator | ✅ All 5 encoding formats |
| Program Counter | ✅ Reset, increment, branch/jump |
| Register File | ✅ 32×32-bit, x0=0 enforced |
| Data Memory | ✅ Load/store, address decode |
| Branch Comparator | ✅ All 6 branch types |
| Write-back MUX | ✅ All 4 source selects |
| Pipeline integration | ✅ Full fetch-decode-execute-mem-wb |

### Waveforms

Simulations output VCD files to `artifacts/sim_build/`:

```bash
gtkwave artifacts/sim_build/riscv_top_tb.vcd
```

Key signals to examine: `clk`, `pc_out`, `instr_out`, `alu_result_out`, `reg_rs1_out`, `reg_rs2_out`, `wb_data_out`, `led_out`.

Full simulation report: [`README_SIMULATION.txt`](README_SIMULATION.txt)

---

## UART Bootloader Protocol

**Packet format (little-endian):**
```
[4 bytes] payload length (bytes)
[4 bytes] entry point address (0x00000000)
[N bytes] firmware binary
```

**Bootloader sequence:**
1. FPGA powers on / reset pressed
2. Bootloader waits for UART packets (~2 second window)
3. If a packet arrives — data is staged into instruction memory
4. Firmware handoff to CPU execution *(this step is under debug)*
5. If no packet — runs flash contents (if available)

**Upload script:**
```bash
python3 firmware/upload_uart_boot.py   --port /dev/ttyUSB0   --baud 115200   --bin firmware/firmware.bin   --entry 0   --repeat 40   --interval 0.05
```

---

## Firmware Examples

### ping_pong.c — alternating LED pattern

```c
#define LED_ADDR 0x20000000

int main() {
    volatile unsigned int *led = (unsigned int *)LED_ADDR;
    while (1) {
        *led = 0xAA;  // 10101010
        for (int i = 0; i < 1000000; i++);
        *led = 0x55;  // 01010101
        for (int i = 0; i < 1000000; i++);
    }
}
```

### Writing your own app

```bash
cd firmware
# Create myapp.c with int main() { ... }
make APP=myapp uart-upload PORT=/dev/ttyUSB0
```

Available apps: `led_test`, `led0_blink`, `led_showcase`, `ping_pong`, `uart_loopback`

---

## Known Limitations

- **RV32I only** — no M, A, F, or D extensions
- **No interrupts** — bare-metal polling only
- **Limited RAM** — 4 KB code + 4 KB data
- **No caches** — direct memory access, CPI ≈ 1
- **Machine mode only** — no user/supervisor privilege levels

---

## References

- [RISC-V ISA Manual](https://riscv.org/)
- [Yosys Documentation](http://www.clifford.at/yosys/)
- [nextpnr Documentation](https://github.com/YosysHQ/nextpnr)
- [prjxray (F4PGA)](https://github.com/f4pga/prjxray)
- [Numato Mimas A7 Board](https://numato.com/product/mimas-a7-artix-7-fpga-development-board/)

---
## Developers 
- [Prathamesh Desai](https://github.com/Pratham-Bit-Flip)
- [Girija Ambardekar](https://github.com/girija-8)

---
*Taking a RISC-V processor from a Verilog file all the way to executing firmware on real silicon, using nothing but open-source tools.*

