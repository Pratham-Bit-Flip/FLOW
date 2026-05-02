# FLOW (FPGA Logic Open Workflow)

**Unified Open-Source FPGA Framework for Verilog-to-Bitstream Generation, Simulation, and Debug Utilities**

> 🔗 Part of **[Project Deccan](https://github.com/ritesh-belgudri/project_deccan)** — an open-source FPGA tools and methodologies initiative developed at the FutureG Networks Lab, IIT Dharwad, supported by MEITY’s C2S program.

---

## Overview

FLOW provides a reproducible FPGA development pipeline using entirely open-source tools.
The core hardware project in this repository is a compact RV32I SoC under [`RISC-V/RV32I_SoC/`](RISC-V/RV32I_SoC).

```
RTL → Simulation → Synthesis → P&R → Bitstream → Board Bring-up
```

FLOW keeps the full engineering path visible, not just the final bitstream.
Every stage leaves artifacts and logs — nothing is hidden behind a GUI.
That makes the project easier to debug, extend, teach, and reproduce on new systems.

**Highlights:**
- End-to-end open-source FPGA flow (Yosys + nextpnr-xilinx + prjxray)
- RV32I CPU + SoC integration, verified on real hardware (Numato Mimas A7)
- Unit and integration simulation with Icarus Verilog
- Portable structure — all external tools isolated in the [`tools/`](tools) folder, no absolute paths
- Automatic PPA (Power, Performance, Area) reports at every build
- Every stage visible: Verilog → JSON netlist → FASM → bit frames → bitstream

---

## Current Status

| Component | Status |
|---|---|
| LED bring-up flow | ✅ Working |
| RV32I hardcoded CPU path on board | ✅ Working |
| Bitstream generation (Numato Mimas A7) | ✅ Working |
| UART bootloader (firmware-only updates) | ⚠️ Present, under active debug/tuning |

---

## Quick Start

From repository root:

```bash
cd RISC-V/RV32I_SoC/flows/04_numato_mimas_a7/scripts
FIRMWARE_APP=ping_pong ./run_prjxray_numato_ppa.sh
openFPGALoader -b mimas_a7 -f ../build/top.bit
```

The generated bitstream lands at:
```
RISC-V/RV32I_SoC/flows/04_numato_mimas_a7/build/top.bit
```

### Build Stages

| Stage | Time |
|---|---|
| Firmware compilation (GCC) | 3–5 seconds |
| Synthesis (Yosys) | ~30 seconds |
| Place-and-Route (nextpnr-xilinx) | ~2 minutes |
| Bitstream conversion (xc7frames2bit) | ~10 seconds |
| **Total** | **~3 minutes** |

### Latest Build Results

| Metric | Value |
|---|---|
| **Utilization (LUTs)** | 3228 / 33600 (9.6%) |
| **Utilization (Registers)** | 416 / 67200 (0.6%) |
| **Block RAMs** | 1 / 75 (1.3%) |
| **Fmax** | 46.86 MHz |
| **Bitstream Size** | 2.1 MB |
| **Target** | Numato Mimas A7 (XC7A50T-1FGG484) |
| **Firmware** | ping_pong (RV32I loop demo) |

```bash
# To reproduce the above:
cd RISC-V/RV32I_SoC/flows/04_numato_mimas_a7/scripts
time FIRMWARE_APP=ping_pong ./run_prjxray_numato_ppa.sh
```

---

## Directory Structure

```text
.
├── README.md
├── LED_BLINK/
├── RISC-V/
│   ├── README.md
│   └── RV32I_SoC/
│       ├── README.md
│       ├── Makefile
│       ├── rtl/
│       ├── tb/
│       ├── firmware/
│       ├── init/
│       ├── scripts/
│       ├── flows/
│       ├── docs/
│       ├── artifacts/
│       └── legacy/
├── boards/
└── tools/              ← external toolchain (not system-wide)
    ├── nextpnr-xilinx/
    ├── prjxray/
    └── prjxray-db/
```

---

## Toolchain

| Tool | Version | Purpose |
|---|---|---|
| `yosys` | 0.33 (git sha1 2584903a060) | Synthesis |
| `nextpnr-xilinx` | — | Xilinx 7-series Place-and-Route |
| `prjxray` + `prjxray-db` | — | Xilinx database / bitstream conversion |
| `xc7frames2bit` | — | Frame-to-bitstream conversion |
| `openFPGALoader` | — | Board programming |
| `iverilog` + `vvp` | — | Simulation |
| `riscv64-unknown-elf-gcc` | 13.2.0 | Firmware cross-compilation |
| `Python` | 3.12.3 | Scripting and build automation |

---

## Simulation & Verification

Run all unit and integration testbenches:

```bash
cd RISC-V/RV32I_SoC
make all
```

Run the top-level simulation script (generates logs + waveforms):

```bash
cd RISC-V/RV32I_SoC/scripts
./run_sim.sh
```

---

## RV32I Instruction Scope

Implemented instruction groups:

- **R-type:** ADD, SUB, AND, OR, XOR, SLL, SRL, SRA
- **I-type:** ADDI, ANDI, ORI, XORI, LW
- **S-type:** SW
- **B-type:** BEQ, BNE, BLT, BGE, BLTU, BGEU

For module-level details (ALU, decoder, datapath, memory map, UART), see [`RISC-V/RV32I_SoC/README.md`](RISC-V/RV32I_SoC/README.md).

---

## Build Artifacts

All artifacts for the Numato Artix-7 flow are under `RISC-V/RV32I_SoC/flows/04_numato_mimas_a7/`:

```
build/
├── top.json    ← synthesized netlist (Yosys)
├── top.fasm    ← routed design (nextpnr)
├── top.frm     ← frame intermediate
└── top.bit     ← final bitstream

reports/
├── yosys_numato.log
├── nextpnr_numato.log
├── xc7frames2bit_numato.log
├── ppa_numato.csv
└── ppa_numato.md
```

---

## Deployment to Hardware

**Prerequisites:** Numato Mimas A7 board, USB cable (JTAG port), `openFPGALoader` in PATH.

```bash
cd RISC-V/RV32I_SoC/flows/04_numato_mimas_a7
openFPGALoader -b mimas_a7 -f build/top.bit        # flash to board
openFPGALoader -b mimas_a7 -f build/top.bit -v     # with verbose output
```

**Verifying it works:**
- LEDs toggle in pattern: `0x01 → 0x02 → 0x04 → 0x08` (ping_pong firmware)
- No serial output needed for the LED demo

**UART (when bootloader is active):**

```bash
picocom -b 115200 /dev/ttyUSB0
# or
miniterm /dev/ttyUSB0 115200
```

Serial communication is under active development. Use LED toggle as the primary verification method.

> **Demo tip:** If UART bootloading is unstable, demonstrate LED behavior first, show simulation waveforms/logs as verification, then present UART as the advanced path under improvement.

---

## Troubleshooting

**Synthesis fails:**
```bash
which yosys                            # confirm it's in PATH
yosys -p 'read_verilog rtl/**/*.v'    # check for RTL syntax errors
```

**P&R fails (nextpnr-xilinx):**
```bash
ls -la tools/prjxray-db/artix7/xc7a50tfgg484-1/chipdb*.bin     # chipdb must exist
NEXTPNR_WALL_TIMEOUT=1800 ./run_prjxray_numato_ppa.sh            # try longer timeout
cat flows/04_numato_mimas_a7/reports/nextpnr_numato.log          # read the log
```

**Bitstream fails to load:**
```bash
openFPGALoader --list-boards           # confirm board is detected
lsusb | grep Numato                    # check USB connection
```

**Simulation testbenches fail:**
```bash
cd RISC-V/RV32I_SoC && make all       # identifies which test fails
```

---

## Future Work

- [ ] Complete UART bootloader debug (serial communication stability)
- [ ] Add I-cache and D-cache for performance improvement
- [ ] Implement RV32M (multiply extension)
- [ ] Add formal verification for core modules
- [ ] Create multi-cycle CPU variant for lower clock constraints
- [ ] Document memory layout and peripheral access patterns
- [ ] Add more sophisticated firmware examples (tasks, interrupts)

---

## Related Project — Project Deccan

This project is a sub-project and extended implementation within the **[Project Deccan](https://github.com/ritesh-belgudri/project_deccan)** ecosystem.

**Project Deccan** integrates Yosys, nextpnr, IceStorm, and Verilator into a seamless pipeline for iCE40 FPGAs, with automated synthesis, P&R, bitstream generation, and simulation flows. It was developed at **FutureG Networks Lab, IIT Dharwad**, supported by **MEITY’s C2S program** and hardware donations from **Lattice Semiconductor**.

This FLOW repository extends those foundations to **Artix-7 / Xilinx 7-series** via prjxray, with a full **RV32I SoC** as the primary design:

| | Project Deccan | This Project (FLOW) |
|---|---|---|
| **Target FPGA** | iCE40 UP5K (Lattice) | Artix-7 XC7A50T (Xilinx) |
| **Board** | UPduino / ICE40-MDP | Numato Mimas A7 |
| **Toolchain** | Yosys + nextpnr-ice40 + IceStorm | Yosys + nextpnr-xilinx + prjxray |
| **Design** | LED blink / ping-pong examples | RV32I SoC with UART bootloader |
| **Simulation** | Verilator | Icarus Verilog (iverilog) |

> **Upstream:** [github.com/ritesh-belgudri/project_deccan](https://github.com/ritesh-belgudri/project_deccan)

---

*AI tools were used for minor code refactoring, formatting, and documentation improvements. All architecture, design decisions, and implementation logic were independently developed.*
