#!/bin/bash
# Generic RV32I synthesis build (board-agnostic)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build_rv32i"

mkdir -p "$BUILD_DIR"
cd "$SCRIPT_DIR"

echo "[1/1] Yosys synthesis (generic)"
yosys -p "read_verilog \
    rv32i_led_top.v \
    riscv_top.v \
  datapath.v \
    pc.v \
    reg_file.v \
    decoder.v \
    immgen.v \
    alu.v \
    branch_comp.v \
    data_mem.v \
    wb_mux.v \
    instr_mem.v \
    mem_map.v \
    flash_mem.v \
    uart_mmio.v \
    uart_tx.v \
    uart_rx.v \
    uart_bootloader.v; \
  hierarchy -check -top rv32i_led_top; \
  flatten; \
  proc; opt; fsm; opt; memory; opt; \
  write_json $BUILD_DIR/top.json"

echo "Synthesis complete: $BUILD_DIR/top.json"
echo "This script is board-agnostic and does not run place-and-route."
