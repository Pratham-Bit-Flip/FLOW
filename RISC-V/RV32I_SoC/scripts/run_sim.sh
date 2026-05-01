#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RTL_DIR="$PROJECT_DIR/rtl"
TB_DIR="$PROJECT_DIR/tb/integration"
INIT_DIR="$PROJECT_DIR/init"
BUILD_DIR="$PROJECT_DIR/artifacts/sim_build"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}RV32I CPU TESTBENCH SIMULATION${NC}"
echo -e "${BLUE}========================================${NC}"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cp -f "$INIT_DIR/bootrom.hex" "$BUILD_DIR/bootrom.hex" 2>/dev/null || true
cp -f "$INIT_DIR/flash.hex" "$BUILD_DIR/flash.hex" 2>/dev/null || true

# List all required source files
SOURCES=(
    # Core pipeline modules
    "$RTL_DIR/core/pc.v"
    "$RTL_DIR/core/decoder.v"
    "$RTL_DIR/core/immgen.v"
    "$RTL_DIR/core/alu.v"
    "$RTL_DIR/core/branch_comp.v"
    "$RTL_DIR/core/reg_file.v"
    "$RTL_DIR/core/wb_mux.v"
    "$RTL_DIR/peripherals/uart_tx.v"
    "$RTL_DIR/peripherals/uart_rx.v"
    "$RTL_DIR/peripherals/uart_mmio.v"
    "$RTL_DIR/peripherals/uart_bootloader.v"
    "$RTL_DIR/memory/flash_mem.v"
    "$RTL_DIR/memory/mem_map.v"
    "$RTL_DIR/memory/instr_mem.v"
    "$RTL_DIR/memory/data_mem.v"
    "$RTL_DIR/core/datapath.v"
    "$RTL_DIR/top/riscv_top.v"
    "$TB_DIR/riscv_top_tb.v"
)

echo -e "${BLUE}[1/3] Compiling Verilog files...${NC}"

# Check if all source files exist
for src in "${SOURCES[@]}"; do
    if [ ! -f "$src" ]; then
        echo -e "${RED}ERROR: Source file not found: $src${NC}"
        exit 1
    fi
done

# Compile with iverilog
if iverilog -g2009 \
    -o riscv_top_sim \
    "${SOURCES[@]}" 2>&1 | tee compile.log; then
    echo -e "${GREEN}✓ Compilation successful${NC}"
else
    echo -e "${RED}✗ Compilation failed!${NC}"
    cat compile.log
    exit 1
fi

# Run simulation
echo -e "${BLUE}[2/3] Running simulation...${NC}"

if vvp -n riscv_top_sim 2>&1 | tee simulation.log; then
    echo -e "${GREEN}✓ Simulation completed successfully${NC}"
else
    echo -e "${RED}✗ Simulation failed!${NC}"
    cat simulation.log
    exit 1
fi

# Check for VCD file generation
echo -e "${BLUE}[3/3] Verifying output files...${NC}"

if [ -f "riscv_top_tb.vcd" ]; then
    SIZE=$(du -h riscv_top_tb.vcd | cut -f1)
    echo -e "${GREEN}✓ Waveform file generated: riscv_top_tb.vcd ($SIZE)${NC}"
    echo -e "${BLUE}  To view: gtkwave riscv_top_tb.vcd${NC}"
else
    echo -e "${RED}✗ VCD file not generated${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}SIMULATION COMPLETE${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Build directory: $BUILD_DIR"
echo -e "Log files:"
echo -e "  - compile.log  (compilation output)"
echo -e "  - simulation.log (simulation output)"
echo -e "  - riscv_top_tb.vcd (waveform data)"
echo -e "${BLUE}========================================${NC}"
