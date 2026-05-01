#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/artifacts/build_rv32i"

mkdir -p "$BUILD_DIR"

echo "[1/1] Yosys synthesis (generic)"
yosys -p "read_verilog \
    $PROJECT_DIR/rtl/top/rv32i_led_top.v \
    $PROJECT_DIR/rtl/top/riscv_top.v \
    $PROJECT_DIR/rtl/core/datapath.v \
    $PROJECT_DIR/rtl/core/pc.v \
    $PROJECT_DIR/rtl/core/reg_file.v \
    $PROJECT_DIR/rtl/core/decoder.v \
    $PROJECT_DIR/rtl/core/immgen.v \
    $PROJECT_DIR/rtl/core/alu.v \
    $PROJECT_DIR/rtl/core/branch_comp.v \
    $PROJECT_DIR/rtl/memory/data_mem.v \
    $PROJECT_DIR/rtl/core/wb_mux.v \
    $PROJECT_DIR/rtl/memory/instr_mem.v \
    $PROJECT_DIR/rtl/memory/mem_map.v \
    $PROJECT_DIR/rtl/memory/flash_mem.v \
    $PROJECT_DIR/rtl/peripherals/uart_mmio.v \
    $PROJECT_DIR/rtl/peripherals/uart_tx.v \
    $PROJECT_DIR/rtl/peripherals/uart_rx.v \
    $PROJECT_DIR/rtl/peripherals/uart_bootloader.v; \
  hierarchy -check -top rv32i_led_top; \
  flatten; proc; opt; fsm; opt; memory; opt; \
  write_json $BUILD_DIR/top.json"

echo "Synthesis complete: $BUILD_DIR/top.json"
echo "This script is board-agnostic and does not run place-and-route."
