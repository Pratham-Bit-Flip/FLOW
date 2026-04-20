#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/girija/FLOW/RISC-V/CorrectM"
FLOW="$ROOT/flows/01_icestorm_up5k"
BUILD="$FLOW/build"
REPORTS="$FLOW/reports"
TOP="rv32i_led_top"

mkdir -p "$BUILD" "$REPORTS"

SRC=(
  "$ROOT/rv32i_led_top.v"
  "$ROOT/riscv_top.v"
  "$ROOT/pc.v"
  "$ROOT/reg_file.v"
  "$ROOT/decoder.v"
  "$ROOT/immgen.v"
  "$ROOT/alu.v"
  "$ROOT/branch_comp.v"
  "$ROOT/data_mem.v"
  "$ROOT/wb_mux.v"
  "$ROOT/instr_mem.v"
  "$ROOT/mem_map.v"
  "$ROOT/flash_mem.v"
  "$ROOT/uart_mmio.v"
  "$ROOT/uart_tx.v"
  "$ROOT/uart_rx.v"
  "$ROOT/uart_bootloader.v"
)

echo "[ice40] Synthesizing..."
yosys -l "$REPORTS/yosys_ice40.log" -p "read_verilog ${SRC[*]}; synth_ice40 -top $TOP -json $BUILD/top.json; stat" >/dev/null

echo "[ice40] Running nextpnr-ice40..."
nextpnr-ice40 \
  --up5k --package uwg30 \
  --json "$BUILD/top.json" \
  --asc "$BUILD/top.asc" \
  --freq 24 \
  --pcf-allow-unconstrained \
  --report "$REPORTS/nextpnr_ice40_report.json" \
  > "$REPORTS/nextpnr_ice40.log" 2>&1

echo "[ice40] Packing bitstream..."
icepack "$BUILD/top.asc" "$BUILD/top.bin"

echo "[ice40] Extracting PPA..."
python3 "$ROOT/flows/common/scripts/extract_open_ppa.py" \
  --board "ice40UP5K-UWG30" \
  --toolchain "yosys+nextpnr-ice40+icestorm" \
  --report-json "$REPORTS/nextpnr_ice40_report.json" \
  --csv "$REPORTS/ppa_ice40.csv" \
  --md "$REPORTS/ppa_ice40.md"

echo "[ice40] Done. Artifacts in $FLOW"
