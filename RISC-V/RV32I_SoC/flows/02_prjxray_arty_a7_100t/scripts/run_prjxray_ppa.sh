#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLOW="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="$(cd "$FLOW/../.." && pwd)"
BUILD="$FLOW/build"
REPORTS="$FLOW/reports"
CONSTRAINTS="$FLOW/constraints/arty_a7_100t_minimal.xdc"
TOP="rv32i_led_top"

# Allow user to specify nextpnr-xilinx binary, otherwise search common paths
if [ -z "${NEXTPNR_XILINX:-}" ]; then
  # Search for nextpnr-xilinx in common locations
  for path in \
    "$(which nextpnr-xilinx 2>/dev/null)" \
    "../../../tools/nextpnr-xilinx/nextpnr-xilinx" \
    "/usr/local/bin/nextpnr-xilinx" \
    "/usr/bin/nextpnr-xilinx"; do
    if [ -f "$path" ] 2>/dev/null; then
      NEXTPNR_XILINX="$path"
      break
    fi
  done
fi

if [ -z "${NEXTPNR_XILINX:-}" ]; then
  echo "ERROR: nextpnr-xilinx not found. Set NEXTPNR_XILINX environment variable."
  exit 2
fi

mkdir -p "$BUILD" "$REPORTS"

CHIPDB="${CHIPDB:-}"
if [[ -z "$CHIPDB" ]]; then
for c in \
  "$FLOW/local_prjxray_db/chipdb-xc7a100t.bin" \
  "$ROOT/flows/02_prjxray_arty_a7_100t/local_prjxray_db/chipdb-xc7a100t.bin" \
  "$ROOT/flows/02_prjxray_arty_a7_100t/local_prjxray_repo/chipdb/chipdb-xc7a100t.bin"; do
  if [[ -f "$c" ]]; then
    CHIPDB="$c"
    break
  fi
done
fi

# Check if CHIPDB is still not found, suggest PRJXRAY_DB_ROOT
if [[ -z "$CHIPDB" && -n "${PRJXRAY_DB_ROOT:-}" ]]; then
  CHIPDB="$PRJXRAY_DB_ROOT/artix7/xc7a100tcsg324-1/chipdb-xc7a100t.bin"
fi

if [[ -z "$CHIPDB" ]]; then
  for c in \
    "$ROOT/tools/prjxray-db/artix7/xc7a100tcsg324-1/chipdb_rebuilt.bin" \
    "$ROOT/tools/prjxray-db/artix7/xc7a100tcsg324-1/chipdb.bin"; do
    if [[ -f "$c" ]]; then
      CHIPDB="$c"
      break
    fi
  done
fi

if [[ -z "$CHIPDB" ]]; then
  echo "[a7] ERROR: chipdb for xc7a100tcsg324-1 not found."
  echo "[a7] Please set PRJXRAY_DB_ROOT environment variable pointing to your prjxray-db installation."
  exit 2
fi

SRC=(
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

echo "[a7] Synthesizing..."
cd "$ROOT"
yosys -l "$REPORTS/yosys_a7.log" -p "read_verilog ${SRC[*]}; synth_xilinx -abc9 -top $TOP; flatten; write_json flows/02_prjxray_arty_a7_100t/build/top.json; stat" >/dev/null

echo "[a7] Running nextpnr-xilinx..."
if "$NEXTPNR_XILINX" --help 2>&1 | grep -q -- "--fasm"; then
  "$NEXTPNR_XILINX" \
    --chipdb "$CHIPDB" \
    --json "$BUILD/top.json" \
    --xdc "$CONSTRAINTS" \
    --fasm "$BUILD/top.fasm" \
    --freq 25 \
    --timing-allow-fail \
    --placer-heap-cell-placement-timeout 0 \
    --report "$REPORTS/nextpnr_a7_report.json" \
    > "$REPORTS/nextpnr_a7.log" 2>&1
else
  "$NEXTPNR_XILINX" \
    --chipdb "$CHIPDB" \
    --json "$BUILD/top.json" \
    --xdc "$CONSTRAINTS" \
    --phys "$BUILD/top.phys" \
    --freq 25 \
    --timing-allow-fail \
    --placer-heap-cell-placement-timeout 0 \
    --report "$REPORTS/nextpnr_a7_report.json" \
    > "$REPORTS/nextpnr_a7.log" 2>&1
fi

echo "[a7] Creating bitstream..."
if [[ -f "$BUILD/top.fasm" ]] && command -v xc7frames2bit >/dev/null 2>&1; then
  xc7frames2bit --part xc7a100tcsg324-1 --bit "$BUILD/top.bit" "$BUILD/top.fasm" \
    > "$REPORTS/xc7frames2bit.log" 2>&1 || true
else
  echo "[a7] Skipped bitstream generation (no FASM output from selected nextpnr binary)." > "$REPORTS/xc7frames2bit.log"
fi

echo "[a7] Extracting PPA..."
python3 "$ROOT/flows/common/scripts/extract_open_ppa.py" \
  --board "arty-a7-100t" \
  --toolchain "yosys+nextpnr-xilinx+prjxray" \
  --report-json "$REPORTS/nextpnr_a7_report.json" \
  --csv "$REPORTS/ppa_a7.csv" \
  --md "$REPORTS/ppa_a7.md"

echo "[a7] Done. Artifacts in $FLOW"
