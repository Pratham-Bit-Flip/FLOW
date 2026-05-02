# Flow Directory Layout

This directory organizes all verification and implementation flows by toolchain and target board.
Each flow is self-contained — constraints, scripts, build artifacts, and reports all live inside their respective folder.

---

## Flow Status Overview

| Flow | Board / Target | Status |
|---|---|---|
| `00_functional_iverilog` | Simulation only | ✅ Fully Working |
| `01_icestorm_up5k` | iCE40UP5K | 🔧 Structure Ready |
| `02_prjxray_arty_a7_100t` | Arty A7-100T | 🔧 Structure Ready |
| `03_trellis_ecp5` | ECP5 Versa-5G | 🔧 Structure Ready |
| `04_numato_mimas_a7` | Numato Mimas A7 | ✅ Bitstream Uploaded, UART Active |

---

## Flow Details

### `00_functional_iverilog/` — ✅ Complete
Functional simulation using Icarus Verilog. This is the primary active flow used for all RTL verification.

- `bin/` — compiled `.vvp` simulation binaries
- `logs/` — simulation stdout and waveform logs
- **How to run:** All testbenches are driven from the root `Makefile`. Run `make` or target a specific TB like `make riscv_top_tb`.
- **Extend:** Can add waveform dumps (`.vcd`) and a GTKWave launch script here for visual debugging.

---

### `01_icestorm_up5k/` — 🔧 In Progress
Open-source iCE40UP5K implementation flow using Yosys + nextpnr-ice40 + icepack.

- `build/` — intermediate artifacts (`.json`, `.asc`, `.bin`)
- `reports/` — utilization/timing/power reports
- `scripts/` — build and report scripts
- **Next step to complete:** Add `.pcf` pin constraints file for the UP5K board and wire up the Yosys synthesis script.
- **Extend:** Can target any iCE40 board (iCEBreaker, TinyFPGA BX) by swapping the `.pcf` file.

---

### `02_prjxray_arty_a7_100t/` — 🔧 In Progress
Open-source Artix-7 flow using Yosys + nextpnr-xilinx + prjxray tools. Includes local copies of the prjxray toolchain and device database.

- `build/` — intermediate artifacts (`.json`, `.fasm`, `.bit`)
- `constraints/` — `.xdc` pin constraints
- `reports/` — utilization/timing/power reports
- `scripts/` — build and report scripts
- `local_prjxray_db/` — local prjxray device database (no external install needed)
- `local_prjxray_repo/` — local prjxray toolchain clone
- **Next step to complete:** Wire up the Yosys + nextpnr synthesis script targeting the Arty A7-100T.
- **Extend:** Porting to other Xilinx 7-series boards only requires a new `.xdc` file.

---

### `03_trellis_ecp5/` — 🔧 In Progress
Open-source ECP5 flow using Yosys + nextpnr-ecp5 + prjtrellis.

- `build/` — intermediate artifacts (`.json`, `.config`, `.bit`)
- `constraints/` — `.lpf` pin constraints
- `reports/` — utilization/timing/power reports
- `scripts/` — build and report scripts
- Target device: **ECP5 Versa-5G** (`LFE5UM5G-45F-8BG381C`), top module: `rv32i_versa5g_top.v`
- **Next step to complete:** Complete the nextpnr-ecp5 script and link the `.lpf` constraints.
- **Extend:** Can be ported to any ECP5 board (OrangeCrab, ULX3S) with a new `.lpf`.

---

### `04_numato_mimas_a7/` — ✅ Active Board (Bitstream Running)
Open-source Artix-7 flow for the **Numato Mimas A7** — the primary physical target board for this project.

- `build/` — intermediate artifacts (`.json`, `.fasm`, `.bit`)
- `constraints/` — `.xdc` pin constraints for the Mimas A7
- `reports/` — utilization/timing/power reports
- `scripts/` — build and report scripts
- Target device: **`xc7a50tfgg484-1`**, top module: `rv32i_numato_top.v`
- **Achieved:** RV32I bitstream successfully synthesized and uploaded to the Numato Mimas A7. UART communication detected and confirmed working on hardware.
- **Next:** Enable full UART bootloader flow (`WITH_UART_BOOT=1`) to allow firmware-only updates without re-synthesizing the bitstream.

---

### `common/`
Shared resources available across all flows.

- `scripts/` — shared helper utilities (e.g., hex generation, firmware upload)
- **Planned additions:** Shared firmware images, merged PPA (Power/Performance/Area) comparison reports across all flows.

---

## Toolchain Requirements

| Flow | Tools Needed |
|---|---|
| `00_functional_iverilog` | `iverilog`, `vvp` |
| `01_icestorm_up5k` | `yosys`, `nextpnr-ice40`, `icepack`, `iceprog` |
| `02_prjxray_arty_a7_100t` | `yosys`, `nextpnr-xilinx`, `prjxray` (bundled locally) |
| `03_trellis_ecp5` | `yosys`, `nextpnr-ecp5`, `ecppack` (prjtrellis) |
| `04_numato_mimas_a7` | `yosys`, `nextpnr-xilinx`, `prjxray` tools |

## Notes

- Keep per-board artifacts isolated in their own flow directories.
- Never commit large bitstream or build artifacts to git — add them to `.gitignore`.
- The `local_prjxray_db/` and `local_prjxray_repo/` in flow `02` make Xilinx flows self-contained without system-wide installs.
