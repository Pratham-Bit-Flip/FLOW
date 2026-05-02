# RV32I RISC-V Processor with UART Bootloader Debug Path

A complete open-source **32-bit RISC-V (RV32I) soft processor** written in Verilog, targeting Xilinx Artix-7 FPGAs. The UART bootloader path is present, but firmware upload is still under debug and is not yet reliable enough to describe as fully working.

## Features

- ✅ **RV32I ISA Compliance** - Subset of RISC-V base instruction set
- 🚧 **UART Bootloader** - UART activity is detected, but firmware programming is still under debug
- ✅ **MMIO LED Control** - Memory-mapped LED outputs
- ✅ **Hardware Heartbeat** - Independent LED blink proves FPGA alive
- ✅ **JTAG Programming** - Full bitstream via OpenFPGALoader
- ✅ **Fully Open-Source** - Yosys + nextpnr-xilinx + prjxray toolchain

## Quick Start

### 1. **One-Time FPGA Bitstream Flash**
```bash
cd flows/04_numato_mimas_a7/scripts
FIRMWARE_APP=ping_pong ./run_prjxray_numato_ppa.sh
openFPGALoader -b mimas_a7 -f ../build/top.bit
```

### 2. **UART Firmware Upload Path (Under Debug)**
```bash
cd firmware
make APP=ping_pong uart-upload PORT=/dev/ttyUSB0 BAUD=115200
```

This command path is kept for reference, but UART programming is not yet reliable enough for a full claim of support.

### 3. **Modify & Repeat**
Edit any `.c` app in `firmware/`, then:
```bash
make APP=myapp uart-upload PORT=/dev/ttyUSB0
```

This is the intended workflow once UART programming is stabilized.

---

## Project Structure

```
.
├── README.md
├── firmware/                # Bare-metal C apps, startup, linker, UART uploader
├── rtl/
│   ├── core/                # ALU, decoder, datapath, PC, regfile, write-back
│   ├── memory/              # Instruction/data/flash memories, memory map
│   ├── peripherals/         # UART and bootloader blocks
│   └── top/                 # SoC and board wrappers
├── tb/
│   ├── unit/                # Module-level testbenches
│   └── integration/         # Top-level and SoC testbenches
├── init/                    # bootrom.hex / flash.hex
├── scripts/                 # run_sim.sh, run_all_tests.sh, build_rv32i.sh
├── flows/                   # FPGA build flows and board constraints
├── docs/                    # Bootloader, memory map, and simulation notes
├── artifacts/               # Generated JSON, SVG, reports, and sim builds
├── tools/                   # External EDA tools and FPGA databases (top-level)
└── legacy/                  # Unused or experimental modules
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

External tool sources and databases are stored under `../../tools/` from the repository root.

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
cd flows/04_numato_mimas_a7/scripts
FIRMWARE_APP=ping_pong ./run_prjxray_numato_ppa.sh
```

Outputs: `../build/top.bit` (Artix-7 bitstream)

---

## UART Bootloader Protocol (Under Validation)

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
3. If packet is received, the bootloader currently detects UART activity and begins staging data
4. Firmware programming and reliable handoff to execution are still being debugged
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

### Run Individual Module Tests
```bash
cd /path/to/RV32I_SoC
make alu_tb              # Test ALU
make decoder_tb          # Test Decoder
make immgen_tb           # Test Immediate Generator
make pc_tb               # Test Program Counter
make reg_file_tb         # Test Register File
make data_mem_tb         # Test Data Memory
make branch_comp_tb      # Test Branch Comparator
make wb_mux_tb           # Test Write-back Multiplexer
make test_bootrom_tb     # Test Boot ROM
```

### Run Integration Tests
```bash
make riscv_top_tb        # Test complete CPU
make riscv_integration_tb # Test SoC integration
make rv32i_led_top_tb    # Test board wrapper
```

### Run All Tests
```bash
make all                 # Run all testbenches
make clean              # Clean generated files
make help               # Show all targets
```

### Waveform Analysis

Each simulation generates a **VCD (Value Change Dump)** waveform file:

**Location:** `artifacts/sim_build/`  
**Format:** IEEE 1364 VCD (viewable in GTKWave)  
**Clock:** 100 MHz (10 ns period)  
**Duration:** ~825 µs (80,000+ cycles)

**View Waveforms:**
```bash
cd artifacts/sim_build
gtkwave riscv_top_tb.vcd
```

**Key Signals to Examine:**
- `clk` - System clock (100 MHz)
- `pc_out` - Program Counter trace
- `instr_out` - Instruction being executed
- `alu_result_out` - ALU computation results
- `reg_rs1_out`, `reg_rs2_out` - Register operands
- `wb_data_out` - Write-back data to registers
- `led_out` - Memory-mapped LED outputs

### Simulation Coverage

All RV32I modules tested:
- ✓ **ALU** - All arithmetic/logic operations (ADD, SUB, AND, OR, XOR, SLT, SLL, SRL, SRA, NOP)
- ✓ **Decoder** - All RV32I instruction formats (R, I, S, B, U, J)
- ✓ **Immediate Generator** - 5 immediate format encoding (I, S, B, U, J)
- ✓ **Program Counter** - Reset, increment, branch/jump targets
- ✓ **Register File** - 32×32-bit read/write, x0 hardwired zero
- ✓ **Data Memory** - Load/store operations, address decoding
- ✓ **Branch Comparator** - All 6 branch types (BEQ, BNE, BLT, BGE, BLTU, BGEU)
- ✓ **Write-back MUX** - Selects correct data source (ALU, memory, PC+4, upper immediate)
- ✓ **Pipeline Integration** - Full 5-stage fetch-decode-execute-memory-writeback flow

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
