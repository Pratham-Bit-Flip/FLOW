# FLOW (FPGA Logic Open Workflow)

**Unified Open-Source FPGA Framework for Verilog-to-Bitstream Generation, Simulation, and Debug Utilities**

This guide documents the practical flow used in this repository for synthesis, place-and-route, bitstream creation, simulation, and board validation.

## 1) Introduction

FLOW provides a reproducible FPGA development pipeline using open-source tools.
The core hardware project in this repository is a compact RV32I SoC under [RISC-V/RV32I_SoC](RISC-V/RV32I_SoC).

Pipeline coverage:

`RTL -> Simulation -> Synthesis -> P&R -> Bitstream -> Board Bring-up`

## 2) Features

- End-to-end open-source FPGA flow
- RV32I CPU + SoC integration in Verilog
- Unit and integration simulation support
- Artix-7 bitstream generation with open tooling
- Build reports and logs for each stage
- Portable structure with external toolchain isolated in a dedicated [tools](tools) folder

## 3) Current Status

- LED bring-up flow: working
- RV32I hardcoded CPU path on board: working
- Bitstream generation flow (Numato Mimas A7): working
- UART bootloader path: present and under active debug/tuning

## 4) Directory Structure

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
└── tools/
```

External tools are intentionally placed at repository root:

```text
tools/
├── nextpnr-xilinx/
├── prjxray/
└── prjxray-db/
```

## 5) Toolchain

- `yosys` 0.33 (git sha1 2584903a060) for synthesis
- `nextpnr-xilinx` for Xilinx 7-series place-and-route
- `prjxray` and `prjxray-db` for Xilinx database/conversion flow
- `xc7frames2bit` for frame-to-bitstream conversion
- `openFPGALoader` for board programming
- `iverilog` and `vvp` for simulation
- `riscv64-unknown-elf-gcc` 13.2.0 for firmware cross-compilation
- `Python` 3.12.3 for scripting and build automation

## 6) Quick Start (Working Hardware Path)

From repository root:

```bash
cd RISC-V/RV32I_SoC/flows/04_numato_mimas_a7/scripts
FIRMWARE_APP=ping_pong ./run_prjxray_numato_ppa.sh
openFPGALoader -b mimas_a7 -f ../build/top.bit
```

The generated bitstream is:

`RISC-V/RV32I_SoC/flows/04_numato_mimas_a7/build/top.bit`

## 6a) Build Results and Performance

Latest successful build:

| Metric | Value |
|---|---|
| **Bitstream Size** | 2.1 MB |
| **Utilization (LUTs)** | 3228 / 33600 (9.6%) |
| **Utilization (Registers)** | 416 / 67200 (0.6%) |
| **Block RAMs** | 1 / 75 (1.3%) |
| **Fmax** | 46.86 MHz |
| **Build Time** | ~3 minutes |
| **Target** | Numato Mimas A7 (XC7A50T-1FGG484) |
| **Firmware** | ping_pong (RV32I loop demo) |

**Build Command:**

```bash
cd RISC-V/RV32I_SoC/flows/04_numato_mimas_a7/scripts
time FIRMWARE_APP=ping_pong ./run_prjxray_numato_ppa.sh
```

**Build Stages:**
1. Firmware compilation (GCC): 3–5 seconds
2. Synthesis with Yosys: ~30 seconds
3. Place-and-Route with nextpnr-xilinx: ~2 minutes
4. Frame-to-bitstream conversion (xc7frames2bit): ~10 seconds

**Key Achievements:**

✓ Open-source flow generates working bitstreams  
✓ RV32I processor verified on real hardware (hardcoded path)  
✓ Portable build: no absolute paths, all tools under [tools](tools) folder  
✓ Low resource utilization enables future expansion (I/O, memory, accelerators)  
✓ Clean tool isolation keeps project code separate from dependencies  

## 7) Simulation and Verification

Run unit and integration tests:

```bash
cd RISC-V/RV32I_SoC
make all
```

Run top-level simulation script:

```bash
cd RISC-V/RV32I_SoC/scripts
./run_sim.sh
```

## 8) Build Artifacts and Reports

For the Numato Artix-7 flow, artifacts are produced under:

`RISC-V/RV32I_SoC/flows/04_numato_mimas_a7/`

Key outputs:

- `build/top.json` (synthesized netlist)
- `build/top.fasm` (routed feature file)
- `build/top.frm` (frame intermediate)
- `build/top.bit` (final bitstream)
- `reports/yosys_numato.log`
- `reports/nextpnr_numato.log`
- `reports/xc7frames2bit_numato.log`
- `reports/ppa_numato.csv`
- `reports/ppa_numato.md`

## 9) RV32I Scope

Implemented RV32I groups used in this project:

- R-type: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA
- I-type: ADDI, ANDI, ORI, XORI, LW
- S-type: SW
- B-type: BEQ, BNE, BLT, BGE, BLTU, BGEU

For module-level details, see:

`RISC-V/RV32I_SoC/README.md`

## 10) Recommended Demo Strategy

If UART bootloading is unstable on a given setup, use this order:

1. Demonstrate hardcoded CPU LED behavior on hardware
2. Show simulation waveforms/logs as verification evidence
3. Present UART bootloader as advanced path under improvement

This provides a reliable and honest demonstration of working CPU + SoC functionality.

## 11) Project Advantages

**What Makes This Flow Stand Out:**

1. **Fully Open-Source Toolchain** – No proprietary CAD tools required. Uses Yosys, nextpnr-xilinx, and Project Trellis-derived prjxray. Reproducible on any Linux system with build tools.

2. **Hardware Verified** – RV32I CPU has been tested on real silicon (Numato Mimas A7), not simulation-only. Bootloader, LED toggling, and core instruction paths proven working.

3. **Honest Documentation** – Clearly states what works (hardcoded CPU) and what's in progress (dynamic UART bootloading). No hidden workarounds or undocumented manual steps.

4. **Portable by Default** – No hardcoded absolute paths. All external tools isolated in [tools](tools) folder. Build scripts use relative paths and environment variables. Works across different systems and user directories.

5. **Modular Architecture** – RTL organized by intent (core/, memory/, peripherals/), not files. Testbenches split into unit and integration tests. Firmware built independently. Easy to swap modules or reuse components.

6. **Low Overhead** – Unoptimized RV32I uses only ~10% of LUT resources on a mid-range Artix-7. Room for caches, complex peripherals, or additional accelerators without changing boards.

7. **Teaching Resource** – Every stage is visible: Verilog → JSON netlist → FASM → bit frames → bitstream. Ideal for learning digital design, FPGA workflows, and processor architecture.

8. **Reproducible Reports** – PPA (Power, Performance, Area) metrics automatically extracted from P&R logs. Build artifacts preserved with timestamps. Easy to track improvements or regressions.

## 12) Why FLOW

FLOW keeps the full engineering path visible, not just final bitstreams.
That makes the project easier to debug, extend, teach, and reproduce on new systems.

## 13) Deployment to Hardware

**Prerequisites:**

- Numato Mimas A7 FPGA board
- USB cable connected to FPGA JTAG port
- `openFPGALoader` tool installed and in PATH

**Load Bitstream:**

```bash
cd RISC-V/RV32I_SoC/flows/04_numato_mimas_a7
openFPGALoader -b mimas_a7 -f build/top.bit
```

Or with verbose output:

```bash
openFPGALoader -b mimas_a7 -f build/top.bit -v
```

**Verify Success:**

- LEDs should toggle in a predictable pattern (ping_pong firmware loops 0x01 → 0x02 → 0x04 → 0x08 on LEDs 3–0)
- No serial output required for the LED demo
- Check FPGA temperature and power consumption on board LEDs

**Serial Port (for future UART debug):**

If UART bootloader is enabled:

```bash
miniterm /dev/ttyUSB0 115200
```

or

```bash
picocom -b 115200 /dev/ttyUSB0
```

Currently, serial communication is under development. Use the LED toggle demonstration as the primary verification method.

## 14) Troubleshooting

**Build fails at synthesis:**

- Ensure `yosys` is in PATH: `which yosys`
- Check RTL files for syntax errors: `yosys -p 'read_verilog rtl/**/*.v'`

**Build fails at P&R (nextpnr-xilinx):**

- Verify chipdb exists: `ls -la tools/prjxray-db/artix7/xc7a50tfgg484-1/chipdb*.bin`
- Try increasing timeout: `NEXTPNR_WALL_TIMEOUT=1800 ./run_prjxray_numato_ppa.sh`
- Check nextpnr log: `cat flows/04_numato_mimas_a7/reports/nextpnr_numato.log`

**Bitstream fails to load:**

- Verify board is detected: `openFPGALoader --list-boards`
- Check USB connection and permissions: `lsusb | grep Numato`
- Re-download bitstream: `openFPGALoader -b mimas_a7 -f build/top.bit -v`

**Simulation testbenches fail:**

- Run: `cd RISC-V/RV32I_SoC && make all` to see which test fails
- Check individual testbench: `make test_alu_unit` (or other unit test)
- Review testbench in `tb/unit/` for expected behavior

## 15) Future Work

- [ ] Complete UART bootloader debug (serial communication stability)
- [ ] Add I-cache and D-cache for performance improvement
- [ ] Implement RV32M (multiply extension)
- [ ] Add formal verification for core modules
- [ ] Create multi-cycle CPU variant for lower clock constraints
- [ ] Document memory layout and peripheral access patterns
- [ ] Add more sophisticated firmware examples (tasks, interrupts)

### Note :
“AI tools were used for minor code refactoring, formatting, and documentation improvements. All architecture, design decisions, and implementation logic were independently developed.”
