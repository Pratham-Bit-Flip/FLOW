# RV32I RISC-V Processor with UART Bootloader

A complete open-source **32-bit RISC-V (RV32I) soft processor** written in Verilog, targeting Xilinx Artix-7 FPGAs. Features a UART bootloader for firmware-only updates without FPGA rebuilds.

## Features

- ✅ **RV32I ISA Compliance** - Subset of RISC-V base instruction set
- ✅ **UART Bootloader** - Load C firmware over serial (115200 baud, 8N1)
- ✅ **MMIO LED Control** - Memory-mapped LED outputs
- ✅ **Hardware Heartbeat** - Independent LED blink proves FPGA alive
- ✅ **JTAG Programming** - Full bitstream via OpenFPGALoader
- ✅ **Fully Open-Source** - Yosys + nextpnr-xilinx + prjxray toolchain

## Quick Start

### 1. **One-Time FPGA Bitstream Flash**
```bash
cd flows/04_prjxray_numato_mimas_a7_50t/scripts
FIRMWARE_APP=ping_pong ./run_prjxray_numato_ppa.sh
openFPGALoader -b mimas_a7 -f ../build/top.bit
```

### 2. **Upload C Firmware via UART**
```bash
cd firmware
make APP=ping_pong uart-upload PORT=/dev/ttyUSB0 BAUD=115200
```

Press **reset** on the board. LEDs start blinking!

### 3. **Modify & Repeat**
Edit any `.c` app in `firmware/`, then:
```bash
make APP=myapp uart-upload PORT=/dev/ttyUSB0
```

No FPGA rebuild needed! 🚀

---

## Project Structure

```
.
├── README.md                           ← This file
├── BOOTLOADER.md                       ← UART protocol docs
│
├── firmware/                           ← C firmware (user apps)
│   ├── Makefile                       ← Build & upload targets
│   ├── upload_uart_boot.py            ← UART bootloader uploader
│   ├── ping_pong.c                    ← Example: LED blink app
│   ├── led_showcase.c                 ← Example: LED patterns
│   ├── crt0.S                         ← RISC-V startup assembly
│   └── link.ld                        ← Linker script
│
├── rtl/                               ← HDL (Verilog source)
│   ├── riscv_top.v                   ← CPU core (WITH_UART_BOOT)
│   ├── rv32i_led_top.v               ← Top-level board wrapper
│   ├── uart_bootloader.v             ← UART protocol handler
│   ├── uart_rx.v, uart_tx.v          ← UART transceiver
│   ├── alu.v, decoder.v              ← CPU datapath
│   ├── reg_file.v, pc.v              ← CPU state
│   └── *.v                           ← Other modules
│
├── sim/                               ← Simulation testbenches
│   ├── run_sim.sh                    ← Simulation runner
│   ├── riscv_top_tb.v                ← CPU testbench
│   └── *_tb.v                        ← Module testbenches
│
├── flows/04_prjxray_numato_mimas_a7_50t/
│   ├── scripts/
│   │   └── run_prjxray_numato_ppa.sh ← Full build flow (synth→place→route)
│   ├── constraints/
│   │   └── numato_mimas_a7_50t.xdc   ← FPGA pin mapping
│   ├── build/                         ← Generated bitstreams (not in repo)
│   └── reports/                       ← Generated reports (not in repo)
│
├── docs/                              ← Documentation
│   ├── SIMULATION_RESULTS.md         ← Test results
│   └── memory_map.md                 ← Address space layout
│
└── .gitignore                         ← Exclude build artifacts
```

---

## Hardware Setup

### Board: Numato Mimas A7 (XC7A50T-1FGG484)

**UART Pin Mapping:**
| Signal | FPGA Pin | GPIO | Module |
|--------|----------|------|--------|
| UART_RX | J21 | B4 | CH340 Module TX |
| UART_TX | K22 | B5 | CH340 Module RX |
| GND | - | GND | CH340 Module GND |

**LED Mapping:**
```
LED[7]   → Hardware Heartbeat (~1Hz blink, no firmware)
LED[6]   → UART RX Activity (toggles per byte received)
LED[5:0] → Firmware MMIO (controlled by C code after boot)
```

---

## Build System

### Prerequisites
```bash
# RISC-V cross-compiler
riscv64-unknown-elf-gcc

# FPGA tools
yosys
nextpnr-xilinx
openFPGALoader

# Python
python3
pyserial
```

### Firmware Build
```bash
cd firmware
make APP=ping_pong          # Build firmware.bin
make APP=ping_pong all      # Full build (GCC compile)
make APP=ping_pong uart-upload     # One attempt
make APP=ping_pong uart-upload-reset  # 40 attempts (more reliable)
```

### FPGA Bitstream Build
```bash
cd flows/04_prjxray_numato_mimas_a7_50t/scripts
FIRMWARE_APP=ping_pong ./run_prjxray_numato_ppa.sh
```

Outputs: `../build/top.bit` (Artix-7 bitstream)

---

## UART Bootloader Protocol

**Packet Format (little-endian):**
```c
[4 bytes] payload length (bytes)
[4 bytes] entry point address (0x00000000)
[N bytes] firmware binary
```

**Upload Command:**
```bash
python3 upload_uart_boot.py \
  --port /dev/ttyUSB0 \
  --baud 115200 \
  --bin firmware.bin \
  --entry 0 \
  --repeat 40 \
  --interval 0.05
```

**Bootloader Sequence:**
1. FPGA powers on / board reset pressed
2. Bootloader waits for UART packets (2-second window)
3. If packet received → load firmware into RAM
4. Jump to entry point → firmware runs
5. If no packet → run flash contents (if available)

---

## Workflow: Firmware-Only Updates

**Goal:** Update C code WITHOUT reprogramming the FPGA

1. **Initial FPGA Setup** (one-time):
   ```bash
   FIRMWARE_APP=ping_pong ./flows/.../scripts/run_prjxray_numato_ppa.sh
   openFPGALoader -b mimas_a7 -f flows/.../build/top.bit
   ```

2. **Iterate on C Code** (repeatable, fast):
   ```bash
   # Edit firmware/myapp.c
   make APP=myapp uart-upload PORT=/dev/ttyUSB0
   # Press reset on board
   # Done! No FPGA rebuild needed
   ```

3. **Results:**
   - Compilation time: **~1 second** (vs 5+ minutes for FPGA rebuild)
   - Upload time: **~0.1 seconds**
   - Device boot time: **<1 second**

---

## Example Firmware Apps

### ping_pong.c - Alternating LED Blink
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

### Create Your Own
```bash
cd firmware
cat > myapp.c << 'EOF'
#define LED_ADDR 0x20000000

int main() {
    volatile unsigned int *led = (unsigned int *)LED_ADDR;
    *led = 0xFF;  // Turn on all LEDs
    while(1);
}
EOF

make APP=myapp uart-upload PORT=/dev/ttyUSB0
```

---

## Testing & Simulation

### Run Simulation
```bash
cd sim
./run_sim.sh
```

Generates: `sim_build/waveform.vcd` (view in GTKWave)

### Run All Tests
```bash
./run_all_tests.sh
```

---

## Architecture Overview

### CPU Core (RV32I)
- **Pipeline:** 5-stage (Fetch → Decode → Execute → Memory → WriteBack)
- **Memory:** 4KB instruction RAM + 4KB data RAM
- **ALU:** Full RV32I arithmetic & logic operations
- **Registers:** 32×32-bit registers (x0–x31)
- **Special:** PC, branch comparator, immediate generator

### Peripherals
- **UART Bootloader** - Serial firmware loader (115200 baud)
- **MMIO LED** - Memory-mapped LED output (0x20000000)
- **RX Activity Detector** - LED[6] toggles per UART byte

### Board I/O
- **Clock:** 100 MHz (from on-board oscillator)
- **Reset:** Active-low button (external pull-up)
- **UART:** GPIO B4(RX) / B5(TX) via CH340 module
- **LEDs:** 8 outputs (active-high)

---

## Known Limitations

- **RV32I only** (no RV32M, RV32A, RV32F extensions)
- **No interrupt support** (bare-metal only)
- **Limited RAM** (4KB code + 4KB data)
- **No caching** (direct memory access)
- **No privileged modes** (machine mode only)

---

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit changes (`git commit -am 'Add feature'`)
4. Push branch (`git push origin feature/my-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the **MIT License** - see LICENSE file for details.

---

## References

- [RISC-V ISA Manual](https://riscv.org/)
- [Xilinx Artix-7 Datasheet](https://docs.xilinx.com/)
- [Yosys Documentation](http://www.clifford.at/yosys/)
- [nextpnr Documentation](https://github.com/YosysHQ/nextpnr)
- [prjxray](https://github.com/f4pga/prjxray)

---

## Author

Prathamesh Desai

## Support

For questions or issues, please open a GitHub Issue or contact the maintainer.

---

**Last Updated:** April 20, 2026  
**Status:** Active Development ✅
