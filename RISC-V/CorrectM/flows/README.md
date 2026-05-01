# Flow Directory Layout

This directory separates verification and implementation flows by toolchain/board.

## Structure

- `00_functional_iverilog/`
  - Icarus Verilog functional verification logs, waveforms, and run scripts.
- `01_icestorm_up5k/`
  - Open-source iCE40UP5K implementation flow (Yosys + nextpnr-ice40 + icepack).
  - `constraints/` -> `.pcf`
  - `scripts/` -> build and report scripts
  - `build/` -> intermediate artifacts (`.json`, `.asc`, `.bin`)
  - `reports/` -> utilization/timing/power reports
- `02_prjxray_arty_a7_100t/`
  - Open-source Artix-7 flow (Yosys + nextpnr-xilinx + prjxray tools).
  - `constraints/` -> `.xdc`
  - `scripts/` -> build and report scripts
  - `build/` -> intermediate artifacts (`.json`, `.fasm`, `.bit`)
  - `reports/` -> utilization/timing/power reports
- `03_trellis_ecp5/`
  - Open-source ECP5 flow (Yosys + nextpnr-ecp5 + prjtrellis).
  - `constraints/` -> `.lpf`
  - `scripts/` -> build and report scripts
  - `build/` -> intermediate artifacts (`.json`, `.config`, `.bit`)
  - `reports/` -> utilization/timing/power reports
  - Current default target is the ECP5 Versa-5G kit (`LFE5UM5G-45F-8BG381C`) using `rv32i_versa5g_top.v` and `constraints/versa5g.lpf`.
- `04_prjxray_numato_mimas_a7_50t/`
  - Open-source Artix-7 flow for Numato Mimas A7 (Yosys + nextpnr-xilinx + prjxray tools).
  - `constraints/` -> `.xdc`
  - `scripts/` -> build and report scripts
  - `build/` -> intermediate artifacts (`.json`, `.fasm`, `.bit`)
  - `reports/` -> utilization/timing/power reports
  - Default target is `xc7a50tfgg484-1` using `rv32i_numato_top.v`.
- `common/`
  - `firmware/` -> shared firmware images (hello-world hex/bin)
  - `scripts/` -> shared helper scripts
  - `reports/` -> merged PPA summary CSV/MD

## Notes

- `prjxray-db` is available at `/home/girija/IITDh/prjxray-db` and includes `artix7/xc7a100tcsg324-1`.
- `prjtrellis` sources are available at `/home/girija/IITDh/prjtrellis`.
- Keep per-board artifacts isolated in their own flow directories.
