`timescale 1ns / 1ps

module pc_tb;
    reg clk;
    reg rst;
    reg [31:0] next_pc;
    wire [31:0] pc_current;
    
    // Instantiate PC
    pc uut (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc_current(pc_current)
    );
    
    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;
    
    initial begin
        $dumpfile("pc_tb.vcd");
        $dumpvars(0, pc_tb);
        
        $display("\n=== PROGRAM COUNTER VERIFICATION TEST ===\n");
        
        // TEST 1: Reset
        $display("TEST 1: Reset to 0x00000000");
        rst = 1;
        next_pc = 32'hFFFFFFFF;
        #10;
        $display("  PC after reset: 0x%08x (expected 0x00000000)", pc_current);
        if (pc_current == 32'h00000000) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        rst = 0;
        #10;
        
        // TEST 2: Sequential increment (PC + 4)
        $display("\nTEST 2: Sequential increment (PC = 0, 4, 8, 12)");
        next_pc = 32'h00000004; #10;
        $display("  PC: 0x%08x (expected 0x00000004)", pc_current);
        if (pc_current == 32'h00000004) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        next_pc = 32'h00000008; #10;
        $display("  PC: 0x%08x (expected 0x00000008)", pc_current);
        if (pc_current == 32'h00000008) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        next_pc = 32'h0000000C; #10;
        $display("  PC: 0x%08x (expected 0x0000000C)", pc_current);
        if (pc_current == 32'h0000000C) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 3: Jump to specific address
        $display("\nTEST 3: Jump to 0x00001000");
        next_pc = 32'h00001000; #10;
        $display("  PC: 0x%08x (expected 0x00001000)", pc_current);
        if (pc_current == 32'h00001000) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 4: Branch backward (negative offset)
        $display("\nTEST 4: Branch backward to 0x00000F00");
        next_pc = 32'h00000F00; #10;
        $display("  PC: 0x%08x (expected 0x00000F00)", pc_current);
        if (pc_current == 32'h00000F00) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 5: Reset during operation
        $display("\nTEST 5: Reset during operation");
        next_pc = 32'hDEADBEEF;
        rst = 1;
        #10;
        $display("  PC after reset: 0x%08x (expected 0x00000000)", pc_current);
        if (pc_current == 32'h00000000) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        rst = 0;
        #10;
        
        // TEST 6: Large address
        $display("\nTEST 6: Jump to large address 0x80000000");
        next_pc = 32'h80000000; #10;
        $display("  PC: 0x%08x (expected 0x80000000)", pc_current);
        if (pc_current == 32'h80000000) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        $display("\n=== Verification Complete ===\n");
        $finish;
    end
endmodule
