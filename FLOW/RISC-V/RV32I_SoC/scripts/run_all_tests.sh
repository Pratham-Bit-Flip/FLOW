#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/artifacts/sim_build"
mkdir -p "$BUILD_DIR"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          COMPLETE MODULE TEST SUITE - FINAL RUN            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

iverilog -g2009 -o "$BUILD_DIR/test_bootrom_tb" "$ROOT_DIR/rtl/memory/instr_mem.v" "$ROOT_DIR/tb/unit/test_bootrom_tb.v"
iverilog -g2009 -o "$BUILD_DIR/data_mem_tb" "$ROOT_DIR/rtl/memory/data_mem.v" "$ROOT_DIR/tb/unit/data_mem_tb.v"
iverilog -g2009 -o "$BUILD_DIR/alu_tb" "$ROOT_DIR/rtl/core/alu.v" "$ROOT_DIR/tb/unit/alu_tb.v"
iverilog -g2009 -o "$BUILD_DIR/reg_file_tb" "$ROOT_DIR/rtl/core/reg_file.v" "$ROOT_DIR/tb/unit/reg_file_tb.v"
iverilog -g2009 -o "$BUILD_DIR/pc_tb" "$ROOT_DIR/rtl/core/pc.v" "$ROOT_DIR/tb/unit/pc_tb.v"
iverilog -g2009 -o "$BUILD_DIR/branch_comp_tb" "$ROOT_DIR/rtl/core/branch_comp.v" "$ROOT_DIR/tb/unit/branch_comp_tb.v"
iverilog -g2009 -o "$BUILD_DIR/immgen_tb" "$ROOT_DIR/rtl/core/immgen.v" "$ROOT_DIR/tb/unit/immgen_tb.v"
iverilog -g2009 -o "$BUILD_DIR/wb_mux_tb" "$ROOT_DIR/rtl/core/wb_mux.v" "$ROOT_DIR/tb/unit/wb_mux_tb.v"
iverilog -g2009 -o "$BUILD_DIR/decoder_tb" "$ROOT_DIR/rtl/core/decoder.v" "$ROOT_DIR/tb/unit/decoder_tb.v"

total_pass=0
total_fail=0

for test in "$BUILD_DIR/test_bootrom_tb" "$BUILD_DIR/data_mem_tb" "$BUILD_DIR/alu_tb" "$BUILD_DIR/reg_file_tb" "$BUILD_DIR/pc_tb" "$BUILD_DIR/branch_comp_tb" "$BUILD_DIR/immgen_tb" "$BUILD_DIR/wb_mux_tb" "$BUILD_DIR/decoder_tb"; do
    pass=$(vvp "$test" 2>&1 | grep -c "PASS" || true)
    fail=$(vvp "$test" 2>&1 | grep -c "FAIL" || true)
    total_pass=$((total_pass + pass))
    total_fail=$((total_fail + fail))
    echo "[$test] PASS: $pass, FAIL: $fail"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TOTAL: $total_pass PASSED, $total_fail FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
find "$BUILD_DIR" -maxdepth 1 -name '*.vcd' | wc -l | xargs echo "Waveform files generated:"
echo ""
