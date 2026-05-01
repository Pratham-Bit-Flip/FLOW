`timescale 1ns / 1ps

module data_mem_tb;
    reg clk;
    reg memwrite;
    reg memread;
    reg [2:0] funct3;
    reg [31:0] addr;
    reg [31:0] writedata;
    wire [31:0] readdata;
    
    // Instantiate data memory
    data_mem uut (
        .clk(clk),
        .memwrite(memwrite),
        .memread(memread),
        .funct3(funct3),
        .addr(addr),
        .writedata(writedata),
        .readdata(readdata)
    );
    
    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock
    
    integer i;
    
    initial begin
        // Generate waveform file
        $dumpfile("data_mem_tb.vcd");
        $dumpvars(0, data_mem_tb);
        
        $display("\n=== DATA MEMORY VERIFICATION TEST ===\n");
        
        // Initialize signals
        memwrite  = 0;
        memread   = 0;
        funct3    = 3'b000;
        addr      = 32'h00000000;
        writedata = 32'h00000000;
        
        #10;
        
        // ===== TEST 1: Store Word (SW) at address 0 =====
        $display("TEST 1: Store Word (SW) 0x12345678 at addr 0x00");
        addr = 32'h00000000;
        writedata = 32'h12345678;
        funct3 = 3'b010; // LW/SW
        memwrite = 1;
        #10;
        memwrite = 0;
        #10;
        
        // ===== TEST 2: Load Word (LW) from address 0 =====
        $display("TEST 2: Load Word (LW) from addr 0x00");
        addr = 32'h00000000;
        funct3 = 3'b010; // LW
        memread = 1;
        #10;
        $display("  Result: 0x%08x (expected 0x12345678)", readdata);
        if (readdata == 32'h12345678)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        memread = 0;
        #10;
        
        // ===== TEST 3: Store Byte (SB) at offset 2 =====
        $display("\nTEST 3: Store Byte (SB) 0xAA at addr 0x02");
        addr = 32'h00000002;
        writedata = 32'h000000AA;
        funct3 = 3'b000; // LB/SB
        memwrite = 1;
        #10;
        memwrite = 0;
        #10;
        
        // ===== TEST 4: Load Word (LW) - verify byte was stored =====
        $display("TEST 4: Load Word to verify byte store");
        addr = 32'h00000000;
        funct3 = 3'b010; // LW
        memread = 1;
        #10;
        $display("  Result: 0x%08x (expected 0x12AA5678 - byte at offset 2)", readdata);
        if (readdata == 32'h12AA5678)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        memread = 0;
        #10;
        
        // ===== TEST 5: Store Halfword (SH) at address 8 =====
        $display("\nTEST 5: Store Halfword (SH) 0xDEAD at addr 0x08");
        addr = 32'h00000008;
        writedata = 32'h0000DEAD;
        funct3 = 3'b001; // LH/SH
        memwrite = 1;
        #10;
        memwrite = 0;
        #10;
        
        // ===== TEST 6: Load Halfword (LH) - signed =====
        $display("TEST 6: Load Halfword (LH) from addr 0x08");
        addr = 32'h00000008;
        funct3 = 3'b001; // LH
        memread = 1;
        #10;
        $display("  Result: 0x%08x (expected 0xffffDEAD - sign extended)", readdata);
        if (readdata == 32'hffffDEAD)
            $display("  ✓ PASS (sign-extended correctly)");
        else
            $display("  ✗ FAIL");
        memread = 0;
        #10;
        
        // ===== TEST 7: Load Halfword Unsigned (LHU) =====
        $display("\nTEST 7: Load Halfword Unsigned (LHU) from addr 0x08");
        addr = 32'h00000008;
        funct3 = 3'b101; // LHU
        memread = 1;
        #10;
        $display("  Result: 0x%08x (expected 0x0000DEAD - zero extended)", readdata);
        if (readdata == 32'h0000DEAD)
            $display("  ✓ PASS (zero-extended correctly)");
        else
            $display("  ✗ FAIL");
        memread = 0;
        #10;
        
        // ===== TEST 8: Store Byte at different offsets =====
        $display("\nTEST 8: Store different bytes - create 0xAABBCCDD pattern");
        
        // Byte 0: 0xDD
        addr = 32'h00000010;
        writedata = 32'h000000DD;
        funct3 = 3'b000; // SB
        memwrite = 1;
        #10;
        
        // Byte 1: 0xCC
        addr = 32'h00000011;
        writedata = 32'h000000CC;
        memwrite = 1;
        #10;
        
        // Byte 2: 0xBB
        addr = 32'h00000012;
        writedata = 32'h000000BB;
        memwrite = 1;
        #10;
        
        // Byte 3: 0xAA
        addr = 32'h00000013;
        writedata = 32'h000000AA;
        memwrite = 1;
        #10;
        memwrite = 0;
        #10;
        
        // Read back as word
        $display("  Loading word from addr 0x10");
        addr = 32'h00000010;
        funct3 = 3'b010; // LW
        memread = 1;
        #10;
        $display("  Result: 0x%08x (expected 0xAABBCCDD)", readdata);
        if (readdata == 32'hAABBCCDD)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        memread = 0;
        #10;
        
        // ===== TEST 9: Load Byte Unsigned (LBU) =====
        $display("\nTEST 9: Load Byte Unsigned (LBU) from addr 0x13");
        addr = 32'h00000013;
        funct3 = 3'b100; // LBU
        memread = 1;
        #10;
        $display("  Result: 0x%08x (expected 0x000000AA)", readdata);
        if (readdata == 32'h000000AA)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        memread = 0;
        #10;
        
        // ===== TEST 10: Load Byte Signed (LB) - test sign extension =====
        $display("\nTEST 10: Load Byte Signed (LB) from addr 0x13 (0xAA = -86)");
        addr = 32'h00000013;
        funct3 = 3'b000; // LB
        memread = 1;
        #10;
        $display("  Result: 0x%08x (expected 0xFFFFFFAA - sign extended)", readdata);
        if (readdata == 32'hFFFFFFAA)
            $display("  ✓ PASS (sign-extended correctly)");
        else
            $display("  ✗ FAIL");
        memread = 0;
        #10;
        
        $display("\n=== Verification Complete ===\n");
        $finish;
    end
endmodule
