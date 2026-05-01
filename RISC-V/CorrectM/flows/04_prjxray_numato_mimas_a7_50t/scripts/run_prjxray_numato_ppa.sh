#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLOW="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="$(cd "$FLOW/../.." && pwd)"
PROJECT_ROOT="$(cd "$ROOT/../../.." && pwd)"
BUILD="$FLOW/build"
REPORTS="$FLOW/reports"
CONSTRAINTS="$FLOW/constraints/numato_mimas_a7_50t.xdc"
TOP="rv32i_led_top"
PART="xc7a50tfgg484-1"
NEXTPNR_XILINX="${NEXTPNR_XILINX:-$PROJECT_ROOT/nextpnr-xilinx/nextpnr-xilinx}"
PRJXRAY_ROOT="${PRJXRAY_ROOT:-$PROJECT_ROOT/prjxray}"
PRJXRAY_DB="${PRJXRAY_DB:-$PROJECT_ROOT/prjxray-db/artix7}"
NEXTPNR_SEED="${NEXTPNR_SEED:-42}"
NEXTPNR_PLACER_TIMEOUT="${NEXTPNR_PLACER_TIMEOUT:-60}"
FIRMWARE_APP="${FIRMWARE_APP:-ping_pong}"

if ! command -v yosys >/dev/null 2>&1; then
  echo "[numato] ERROR: yosys not found in PATH."
  exit 127
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "[numato] ERROR: python3 not found in PATH."
  exit 127
fi

if [[ ! -x "$NEXTPNR_XILINX" ]]; then
  if command -v nextpnr-xilinx >/dev/null 2>&1; then
    NEXTPNR_XILINX="$(command -v nextpnr-xilinx)"
  else
    echo "[numato] ERROR: nextpnr-xilinx binary not found. Checked: $NEXTPNR_XILINX"
    exit 127
  fi
fi

mkdir -p "$BUILD" "$REPORTS"

CHIPDB="${CHIPDB:-}"
if [[ -z "$CHIPDB" ]]; then
for c in \
  "$FLOW/local_prjxray_db/chipdb_rebuilt.bin" \
  "$FLOW/local_prjxray_db/chipdb.bin" \
  "$ROOT/flows/04_prjxray_numato_mimas_a7_50t/local_prjxray_db/chipdb_rebuilt.bin" \
  "$ROOT/flows/04_prjxray_numato_mimas_a7_50t/local_prjxray_db/chipdb.bin" \
  "$ROOT/flows/04_prjxray_numato_mimas_a7_50t/local_prjxray_repo/chipdb/chipdb-xc7a50t.bin" \
  "$PROJECT_ROOT/prjxray-db/artix7/xc7a50tfgg484-1/chipdb_rebuilt.bin" \
  "$PROJECT_ROOT/prjxray-db/artix7/xc7a50tfgg484-1/chipdb.bin"; do
  if [[ -f "$c" ]]; then
    CHIPDB="$c"
    break
  fi
done
fi

if [[ -z "$CHIPDB" ]]; then
  echo "[numato] ERROR: chipdb for $PART not found."
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

echo "[numato] Building firmware (GCC -> bootrom.hex, APP=$FIRMWARE_APP)..."
make -C "$ROOT/firmware" APP="$FIRMWARE_APP" clean all

echo "[numato] Synthesizing..."
cd "$ROOT"
yosys -l "$REPORTS/yosys_numato.log" -p "read_verilog ${SRC[*]}; synth_xilinx -abc9 -top $TOP; flatten; write_json flows/04_prjxray_numato_mimas_a7_50t/build/top.json; stat" >/dev/null

echo "[numato] Running nextpnr-xilinx..."
if "$NEXTPNR_XILINX" --help 2>&1 | grep -q -- "--fasm"; then
  "$NEXTPNR_XILINX" \
    --chipdb "$CHIPDB" \
    --json "$BUILD/top.json" \
    --xdc "$CONSTRAINTS" \
    --fasm "$BUILD/top.fasm" \
    --seed "$NEXTPNR_SEED" \
    --freq 15 \
    --timing-allow-fail \
    --placer-heap-cell-placement-timeout "$NEXTPNR_PLACER_TIMEOUT" \
    --report "$REPORTS/nextpnr_numato_report.json" \
    > "$REPORTS/nextpnr_numato.log" 2>&1
else
  "$NEXTPNR_XILINX" \
    --chipdb "$CHIPDB" \
    --json "$BUILD/top.json" \
    --xdc "$CONSTRAINTS" \
    --phys "$BUILD/top.phys" \
    --seed "$NEXTPNR_SEED" \
    --freq 15 \
    --timing-allow-fail \
    --placer-heap-cell-placement-timeout "$NEXTPNR_PLACER_TIMEOUT" \
    --report "$REPORTS/nextpnr_numato_report.json" \
    > "$REPORTS/nextpnr_numato.log" 2>&1
fi

echo "[numato] Creating bitstream..."
XC7FRAMES2BIT_BIN="${XC7FRAMES2BIT_BIN:-}"
if [[ -z "$XC7FRAMES2BIT_BIN" ]]; then
  if command -v xc7frames2bit >/dev/null 2>&1; then
    XC7FRAMES2BIT_BIN="$(command -v xc7frames2bit)"
  elif [[ -x "$PRJXRAY_ROOT/build/tools/xc7frames2bit" ]]; then
    XC7FRAMES2BIT_BIN="$PRJXRAY_ROOT/build/tools/xc7frames2bit"
  fi
fi

if [[ -f "$BUILD/top.fasm" ]] && [[ -n "$XC7FRAMES2BIT_BIN" ]] && [[ -f "$PRJXRAY_ROOT/utils/fasm2frames.py" ]] && [[ -d "$PRJXRAY_DB" ]]; then
  PYTHONPATH="$PRJXRAY_ROOT" python3 "$PRJXRAY_ROOT/utils/fasm2frames.py" \
    --db-root "$PRJXRAY_DB" \
    --part "$PART" \
    "$BUILD/top.fasm" "$BUILD/top.frm" \
    > "$REPORTS/fasm2frames_numato.log" 2>&1

  "$XC7FRAMES2BIT_BIN" \
    --part_file "$PRJXRAY_DB/$PART/part.yaml" \
    --part_name "$PART" \
    --frm_file "$BUILD/top.frm" \
    --output_file "$BUILD/top.bit" \
    > "$REPORTS/xc7frames2bit_numato.log" 2>&1
else
  echo "[numato] Skipped bitstream generation (missing FASM, xc7frames2bit, or prjxray conversion inputs)." > "$REPORTS/xc7frames2bit_numato.log"
fi

echo "[numato] Extracting PPA..."
python3 "$ROOT/flows/common/scripts/extract_open_ppa.py" \
  --board "numato-mimas-a7-50t" \
  --toolchain "yosys+nextpnr-xilinx+prjxray" \
  --report-json "$REPORTS/nextpnr_numato_report.json" \
  --csv "$REPORTS/ppa_numato.csv" \
  --md "$REPORTS/ppa_numato.md"

echo "[numato] Done. Artifacts in $FLOW"
