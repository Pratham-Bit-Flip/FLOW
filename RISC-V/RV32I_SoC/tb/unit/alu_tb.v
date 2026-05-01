`timescale 1ns / 1ps

module alu_tb;
    reg [31:0] a, b;
    reg [4:0] alu_op;
    wire [31:0] y;
    wire zero;
    
    // Instantiate ALU
    alu uut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .y(y),
        .zero(zero)
    );
    
    // ALU opcodes
    localparam ALU_ADD    = 5'd0;
    localparam ALU_SUB    = 5'd1;
    localparam ALU_AND    = 5'd2;
    localparam ALU_OR     = 5'd3;
    localparam ALU_XOR    = 5'd4;
    localparam ALU_SLL    = 5'd5;
    localparam ALU_SRL    = 5'd6;
    localparam ALU_SRA    = 5'd7;
    localparam ALU_SLT    = 5'd8;
    localparam ALU_SLTU   = 5'd9;
    localparam ALU_COPY_B = 5'd10;
    
    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);
        
        $display("\n=== ALU VERIFICATION TEST ===\n");
        
        // TEST 1: ADD
        $display("TEST 1: ADD (15 + 10 = 25)");
        a = 32'd15; b = 32'd10; alu_op = ALU_ADD; #10;
        $display("  Result: %d (expected 25)", y);
        if (y == 32'd25) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 2: SUB
        $display("\nTEST 2: SUB (100 - 30 = 70)");
        a = 32'd100; b = 32'd30; alu_op = ALU_SUB; #10;
        $display("  Result: %d (expected 70)", y);
        if (y == 32'd70) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 3: AND
        $display("\nTEST 3: AND (0xFF00 & 0x0F0F = 0x0F00)");
        a = 32'hFF00; b = 32'h0F0F; alu_op = ALU_AND; #10;
        $display("  Result: 0x%08x (expected 0x00000F00)", y);
        if (y == 32'h0F00) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 4: OR
        $display("\nTEST 4: OR (0xF0F0 | 0x0F0F = 0xFFFF)");
        a = 32'hF0F0; b = 32'h0F0F; alu_op = ALU_OR; #10;
        $display("  Result: 0x%08x (expected 0x0000FFFF)", y);
        if (y == 32'hFFFF) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 5: XOR
        $display("\nTEST 5: XOR (0xAAAA ^ 0x5555 = 0xFFFF)");
        a = 32'hAAAA; b = 32'h5555; alu_op = ALU_XOR; #10;
        $display("  Result: 0x%08x (expected 0x0000FFFF)", y);
        if (y == 32'hFFFF) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 6: SLL (Shift Left Logical)
        $display("\nTEST 6: SLL (1 << 4 = 16)");
        a = 32'd1; b = 32'd4; alu_op = ALU_SLL; #10;
        $display("  Result: %d (expected 16)", y);
        if (y == 32'd16) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 7: SRL (Shift Right Logical)
        $display("\nTEST 7: SRL (0x80000000 >> 1 = 0x40000000)");
        a = 32'h80000000; b = 32'd1; alu_op = ALU_SRL; #10;
        $display("  Result: 0x%08x (expected 0x40000000)", y);
        if (y == 32'h40000000) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 8: SRA (Shift Right Arithmetic - preserves sign)
        $display("\nTEST 8: SRA (0x80000000 >>> 1 = 0xC0000000 - sign extended)");
        a = 32'h80000000; b = 32'd1; alu_op = ALU_SRA; #10;
        $display("  Result: 0x%08x (expected 0xC0000000)", y);
        if (y == 32'hC0000000) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 9: SLT (Set Less Than - signed)
        $display("\nTEST 9: SLT (-5 < 10 = 1)");
        a = -5; b = 32'd10; alu_op = ALU_SLT; #10;
        $display("  Result: %d (expected 1)", y);
        if (y == 32'd1) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 10: SLT (10 < 5 = 0)
        $display("\nTEST 10: SLT (10 < 5 = 0)");
        a = 32'd10; b = 32'd5; alu_op = ALU_SLT; #10;
        $display("  Result: %d (expected 0)", y);
        if (y == 32'd0) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 11: SLTU (Set Less Than Unsigned)
        $display("\nTEST 11: SLTU (5 < 10 = 1)");
        a = 32'd5; b = 32'd10; alu_op = ALU_SLTU; #10;
        $display("  Result: %d (expected 1)", y);
        if (y == 32'd1) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 12: SLTU with large unsigned values
        $display("\nTEST 12: SLTU (0xFFFFFFFF < 10 = 0 - unsigned)");
        a = 32'hFFFFFFFF; b = 32'd10; alu_op = ALU_SLTU; #10;
        $display("  Result: %d (expected 0)", y);
        if (y == 32'd0) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 13: COPY_B
        $display("\nTEST 13: COPY_B (copy b = 0xDEADBEEF)");
        a = 32'h12345678; b = 32'hDEADBEEF; alu_op = ALU_COPY_B; #10;
        $display("  Result: 0x%08x (expected 0xDEADBEEF)", y);
        if (y == 32'hDEADBEEF) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 14: Zero flag test
        $display("\nTEST 14: Zero flag (15 - 15 = 0, zero=1)");
        a = 32'd15; b = 32'd15; alu_op = ALU_SUB; #10;
        $display("  Result: %d, zero=%b (expected 0, zero=1)", y, zero);
        if (y == 32'd0 && zero == 1'b1) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        $display("\n=== Verification Complete ===\n");
        $finish;
    end
endmodule
