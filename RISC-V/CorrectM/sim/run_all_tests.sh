#!/bin/bash
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          COMPLETE MODULE TEST SUITE - FINAL RUN            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Compile all tests
mkdir -p sim_build
iverilog -o sim_build/test_bootrom instr_mem.v tb/test_bootrom_tb.v 2>&1 | grep -i error
iverilog -o sim_build/data_mem_test data_mem.v tb/data_mem_tb.v 2>&1 | grep -i error
iverilog -o sim_build/alu_test alu.v tb/alu_tb.v 2>&1 | grep -i error
iverilog -o sim_build/reg_test reg_file.v tb/reg_file_tb.v 2>&1 | grep -i error
iverilog -o sim_build/pc_test pc.v tb/pc_tb.v 2>&1 | grep -i error
iverilog -o sim_build/branch_test branch_comp.v tb/branch_comp_tb.v 2>&1 | grep -i error
iverilog -o sim_build/immgen_test immgen.v tb/immgen_tb.v 2>&1 | grep -i error
iverilog -o sim_build/wb_mux_test wb_mux.v tb/wb_mux_tb.v 2>&1 | grep -i error
iverilog -o sim_build/decoder_test decoder.v tb/decoder_tb.v 2>&1 | grep -i error

total_pass=0
total_fail=0

for test in sim_build/test_bootrom sim_build/data_mem_test sim_build/alu_test sim_build/reg_test sim_build/pc_test sim_build/branch_test sim_build/immgen_test sim_build/wb_mux_test sim_build/decoder_test; do
    pass=$(vvp $test 2>&1 | grep -c "✓ PASS")
    fail=$(vvp $test 2>&1 | grep -c "✗ FAIL")
    total_pass=$((total_pass + pass))
    total_fail=$((total_fail + fail))
    echo "[$test] PASS: $pass, FAIL: $fail"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TOTAL: $total_pass PASSED, $total_fail FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -1 *.vcd 2>/dev/null | wc -l | xargs echo "Waveform files generated:"
echo ""
