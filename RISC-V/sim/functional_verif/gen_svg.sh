#!/usr/bin/env bash
# =============================================================================
# gen_svg.sh — Generate RTL SVG diagrams for all RV32I modules using Yosys
# Run from: /home/prathamesh-desai/Documents/Major-Project/FLOW/RISC-V/CorrectM/
# =============================================================================
CORRECTM="$(cd "$(dirname "$0")/../CorrectM" && pwd)"
SVG_DIR="$(cd "$(dirname "$0")" && pwd)/svg"
mkdir -p "$SVG_DIR"

cd "$CORRECTM"

# Helper: generate SVG for a given module using listed source files
# Usage: gen_svg <module_name> <file1> [file2 ...]
gen_svg() {
    local MOD="$1"; shift
    local FILES="$*"
    local OUT="$SVG_DIR/$MOD"
    local YS="$SVG_DIR/${MOD}_gen.ys"
    echo "  [SVG] $MOD ..."
    # Build a yosys script file (avoids shell quoting / newline issues)
    {
        for f in $FILES; do echo "read_verilog -sv $f"; done
        echo "hierarchy -top $MOD"
        echo "proc"
        echo "opt -noclkinv"
        echo "show -format svg -prefix $OUT $MOD"
    } > "$YS"
    yosys -q -s "$YS" >"$SVG_DIR/${MOD}.log" 2>&1 \
        && echo "        -> ${MOD}.svg OK" \
        || echo "        -> $MOD FAILED (see ${MOD}.log)"
}

echo "======================================="
echo " RTL SVG Generation – All Modules"
echo " Output: $SVG_DIR"
echo "======================================="

# ─── Leaf / simple modules ────────────────────────────────────────────────────
gen_svg alu              alu.v
gen_svg branch_comp      branch_comp.v
gen_svg decoder          decoder.v
gen_svg immgen           immgen.v
gen_svg pc               pc.v
gen_svg reg_file         reg_file.v
gen_svg wb_mux           wb_mux.v
gen_svg led_blink_overlay led_blink_overlay.v
gen_svg uart_tx          uart_tx.v
gen_svg uart_rx          uart_rx.v

# ─── Memory modules ───────────────────────────────────────────────────────────
gen_svg data_mem         data_mem.v
gen_svg flash_mem        flash_mem.v
gen_svg instr_mem        instr_mem.v
gen_svg uart_mmio        uart_mmio.v

# ─── Composite modules ────────────────────────────────────────────────────────
gen_svg uart_bootloader  uart_bootloader.v uart_rx.v

gen_svg mem_map          mem_map.v data_mem.v flash_mem.v uart_mmio.v

gen_svg datapath         datapath.v pc.v reg_file.v decoder.v immgen.v \
                         alu.v branch_comp.v wb_mux.v

# ─── SoC top levels ───────────────────────────────────────────────────────────
ALL_DEPS="datapath.v pc.v reg_file.v decoder.v immgen.v alu.v branch_comp.v \
          wb_mux.v instr_mem.v mem_map.v data_mem.v flash_mem.v uart_mmio.v \
          uart_tx.v uart_rx.v uart_bootloader.v"

gen_svg riscv_top        riscv_top.v $ALL_DEPS

gen_svg rv32i_attosoc    rv32i_attosoc.v riscv_top.v $ALL_DEPS

gen_svg rv32i_soc        rv32i_soc.v riscv_top.v $ALL_DEPS

gen_svg rv32i_led_top    rv32i_led_top.v riscv_top.v $ALL_DEPS

gen_svg rv32i_numato_top rv32i_numato_top.v riscv_top.v $ALL_DEPS

gen_svg rv32i_versa5g_top rv32i_versa5g_top.v rv32i_soc.v riscv_top.v \
                          led_blink_overlay.v $ALL_DEPS

echo "======================================="
echo " Done. SVGs written to:"
echo " $SVG_DIR"
ls "$SVG_DIR"/*.svg 2>/dev/null | while read f; do echo "   $(basename $f)"; done
echo "======================================="
