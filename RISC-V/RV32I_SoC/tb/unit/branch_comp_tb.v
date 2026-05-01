`timescale 1ns / 1ps

module branch_comp_tb;
    reg [31:0] rs1_data, rs2_data;
    reg [2:0] funct3;
    wire take_branch;
    
    // Instantiate branch comparator
    branch_comp uut (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .funct3(funct3),
        .take_branch(take_branch)
    );
    
    initial begin
        $dumpfile("branch_comp_tb.vcd");
        $dumpvars(0, branch_comp_tb);
        
        $display("\n=== BRANCH COMPARATOR VERIFICATION TEST ===\n");
        
        // TEST 1: BEQ (Branch if Equal)
        $display("TEST 1: BEQ (10 == 10 = true)");
        rs1_data = 32'd10; rs2_data = 32'd10; funct3 = 3'b000; #10;
        $display("  take_branch: %b (expected 1)", take_branch);
        if (take_branch == 1'b1) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        $display("\nTEST 2: BEQ (10 == 20 = false)");
        rs1_data = 32'd10; rs2_data = 32'd20; funct3 = 3'b000; #10;
        $display("  take_branch: %b (expected 0)", take_branch);
        if (take_branch == 1'b0) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 3: BNE (Branch if Not Equal)
        $display("\nTEST 3: BNE (10 != 20 = true)");
        rs1_data = 32'd10; rs2_data = 32'd20; funct3 = 3'b001; #10;
        $display("  take_branch: %b (expected 1)", take_branch);
        if (take_branch == 1'b1) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        $display("\nTEST 4: BNE (10 != 10 = false)");
        rs1_data = 32'd10; rs2_data = 32'd10; funct3 = 3'b001; #10;
        $display("  take_branch: %b (expected 0)", take_branch);
        if (take_branch == 1'b0) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 5: BLT (Branch if Less Than - signed)
        $display("\nTEST 5: BLT (-5 < 10 = true)");
        rs1_data = -5; rs2_data = 32'd10; funct3 = 3'b100; #10;
        $display("  take_branch: %b (expected 1)", take_branch);
        if (take_branch == 1'b1) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        $display("\nTEST 6: BLT (10 < 5 = false)");
        rs1_data = 32'd10; rs2_data = 32'd5; funct3 = 3'b100; #10;
        $display("  take_branch: %b (expected 0)", take_branch);
        if (take_branch == 1'b0) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 7: BGE (Branch if Greater or Equal - signed)
        $display("\nTEST 7: BGE (10 >= 5 = true)");
        rs1_data = 32'd10; rs2_data = 32'd5; funct3 = 3'b101; #10;
        $display("  take_branch: %b (expected 1)", take_branch);
        if (take_branch == 1'b1) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        $display("\nTEST 8: BGE (-5 >= 10 = false)");
        rs1_data = -5; rs2_data = 32'd10; funct3 = 3'b101; #10;
        $display("  take_branch: %b (expected 0)", take_branch);
        if (take_branch == 1'b0) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        $display("\nTEST 9: BGE (10 >= 10 = true)");
        rs1_data = 32'd10; rs2_data = 32'd10; funct3 = 3'b101; #10;
        $display("  take_branch: %b (expected 1)", take_branch);
        if (take_branch == 1'b1) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 10: BLTU (Branch if Less Than Unsigned)
        $display("\nTEST 10: BLTU (5 < 10 = true)");
        rs1_data = 32'd5; rs2_data = 32'd10; funct3 = 3'b110; #10;
        $display("  take_branch: %b (expected 1)", take_branch);
        if (take_branch == 1'b1) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        $display("\nTEST 11: BLTU (0xFFFFFFFF < 10 = false - unsigned)");
        rs1_data = 32'hFFFFFFFF; rs2_data = 32'd10; funct3 = 3'b110; #10;
        $display("  take_branch: %b (expected 0)", take_branch);
        if (take_branch == 1'b0) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 12: BGEU (Branch if Greater or Equal Unsigned)
        $display("\nTEST 12: BGEU (10 >= 5 = true)");
        rs1_data = 32'd10; rs2_data = 32'd5; funct3 = 3'b111; #10;
        $display("  take_branch: %b (expected 1)", take_branch);
        if (take_branch == 1'b1) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        $display("\nTEST 13: BGEU (0xFFFFFFFF >= 10 = true - unsigned)");
        rs1_data = 32'hFFFFFFFF; rs2_data = 32'd10; funct3 = 3'b111; #10;
        $display("  take_branch: %b (expected 1)", take_branch);
        if (take_branch == 1'b1) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        $display("\n=== Verification Complete ===\n");
        $finish;
    end
endmodule
