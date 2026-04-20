#!/bin/bash

# RV32I CPU Testbench Simulation Script
# Uses Icarus Verilog (iverilog) for compilation and simulation

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESIGN_DIR="$SCRIPT_DIR"
TB_DIR="$DESIGN_DIR/tb"
BUILD_DIR="$DESIGN_DIR/sim_build"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}RV32I CPU TESTBENCH SIMULATION${NC}"
echo -e "${BLUE}========================================${NC}"

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Copy ROM init files into build directory
cp -f "$DESIGN_DIR/bootrom.hex" "$BUILD_DIR/bootrom.hex"
cp -f "$DESIGN_DIR/flash.hex" "$BUILD_DIR/flash.hex"

# List all required source files
SOURCES=(
    # Core pipeline modules
    "$DESIGN_DIR/pc.v"
    "$DESIGN_DIR/decoder.v"
    "$DESIGN_DIR/immgen.v"
    "$DESIGN_DIR/alu.v"
    "$DESIGN_DIR/branch_comp.v"
    "$DESIGN_DIR/reg_file.v"
    "$DESIGN_DIR/wb_mux.v"
    "$DESIGN_DIR/uart_tx.v"
    "$DESIGN_DIR/uart_rx.v"
    "$DESIGN_DIR/uart_mmio.v"
    "$DESIGN_DIR/uart_bootloader.v"
    "$DESIGN_DIR/flash_mem.v"
    "$DESIGN_DIR/mem_map.v"
    # Memory modules
    "$DESIGN_DIR/instr_mem.v"
    "$DESIGN_DIR/data_mem.v"
    # Top-level module
    "$DESIGN_DIR/riscv_top.v"
    "$DESIGN_DIR/datapath.v"
    # Testbench
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
