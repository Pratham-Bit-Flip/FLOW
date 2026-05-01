#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLOW="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="$(cd "$FLOW/../.." && pwd)"
BUILD="$FLOW/build"
REPORTS="$FLOW/reports"
TOP="${TOP:-rv32i_versa5g_top}"

# Override these from environment for your board.
ECP5_DEVICE="${ECP5_DEVICE:-um5g-45k}"  # 25k|45k|85k|um5g-45k
ECP5_PACKAGE="${ECP5_PACKAGE:-CABGA381}"
ECP5_SPEED="${ECP5_SPEED:-8}"
ECP5_LPF="${ECP5_LPF:-$FLOW/constraints/versa5g.lpf}"

mkdir -p "$BUILD" "$REPORTS"

SRC=(
  "rv32i_soc.v"
  "led_blink_overlay.v"
  "rv32i_versa5g_top.v"
  "rv32i_led_top.v"
  "riscv_top.v"
  "datapath.v"
  "pc.v"
  "reg_file.v"
  "decoder.v"
  "immgen.v"
  "alu.v"
  "branch_comp.v"
  "data_mem.v"
  "wb_mux.v"
  "instr_mem.v"
  "mem_map.v"
  "flash_mem.v"
  "uart_mmio.v"
  "uart_tx.v"
  "uart_rx.v"
  "uart_bootloader.v"
)

echo "[ecp5] Synthesizing..."
cd "$ROOT"
yosys -l "$REPORTS/yosys_ecp5.log" -p "read_verilog ${SRC[*]}; synth_ecp5 -top $TOP; flatten; delete t:\$scopeinfo; clean -purge; write_json flows/03_trellis_ecp5/build/top.json; stat" >/dev/null

echo "[ecp5] Running nextpnr-ecp5..."
nextpnr-ecp5 \
  --"$ECP5_DEVICE" --package "$ECP5_PACKAGE" \
  --speed "$ECP5_SPEED" \
  --json "$BUILD/top.json" \
  --lpf "$ECP5_LPF" \
  --textcfg "$BUILD/top.config" \
  --freq 25 \
  --report "$REPORTS/nextpnr_ecp5_report.json" \
  > "$REPORTS/nextpnr_ecp5.log" 2>&1

echo "[ecp5] Packing bitstream..."
if command -v ecppack >/dev/null 2>&1; then
  ecppack "$BUILD/top.config" "$BUILD/top.bit" > "$REPORTS/ecppack.log" 2>&1
else
  echo "ecppack not found" > "$REPORTS/ecppack.log"
fi

echo "[ecp5] Extracting PPA..."
python3 "$ROOT/flows/common/scripts/extract_open_ppa.py" \
  --board "ecp5-$ECP5_DEVICE-$ECP5_PACKAGE" \
  --toolchain "yosys+nextpnr-ecp5+prjtrellis" \
  --report-json "$REPORTS/nextpnr_ecp5_report.json" \
  --csv "$REPORTS/ppa_ecp5.csv" \
  --md "$REPORTS/ppa_ecp5.md"

echo "[ecp5] Done. Artifacts in $FLOW"
