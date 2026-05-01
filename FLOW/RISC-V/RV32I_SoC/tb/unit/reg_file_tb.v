`timescale 1ns / 1ps

module reg_file_tb;
    reg clk;
    reg wr_en;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] wr_data;
    wire [31:0] rd_data1, rd_data2;
    
    // Instantiate register file
    reg_file uut (
        .clk(clk),
        .wr_en(wr_en),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wr_data(wr_data),
        .rd_data1(rd_data1),
        .rd_data2(rd_data2)
    );
    
    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;
    
    initial begin
        $dumpfile("reg_file_tb.vcd");
        $dumpvars(0, reg_file_tb);
        
        $display("\n=== REGISTER FILE VERIFICATION TEST ===\n");
        
        // Initialize
        wr_en = 0;
        rs1 = 0; rs2 = 0; rd = 0;
        wr_data = 0;
        #10;
        
        // TEST 1: Write to x5, read back
        $display("TEST 1: Write 0xDEADBEEF to x5");
        rd = 5'd5;
        wr_data = 32'hDEADBEEF;
        wr_en = 1;
        #10;
        wr_en = 0;
        rs1 = 5'd5;
        #10;
        $display("  Read x5: 0x%08x (expected 0xDEADBEEF)", rd_data1);
        if (rd_data1 == 32'hDEADBEEF) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 2: Write to multiple registers
        $display("\nTEST 2: Write to x10 = 100, x11 = 200");
        rd = 5'd10; wr_data = 32'd100; wr_en = 1; #10;
        rd = 5'd11; wr_data = 32'd200; #10;
        wr_en = 0;
        rs1 = 5'd10; rs2 = 5'd11; #10;
        $display("  Read x10: %d, x11: %d (expected 100, 200)", rd_data1, rd_data2);
        if (rd_data1 == 32'd100 && rd_data2 == 32'd200) 
            $display("  ✓ PASS"); 
        else 
            $display("  ✗ FAIL");
        
        // TEST 3: x0 should always be zero
        $display("\nTEST 3: x0 hardwired to zero (attempt write)");
        rd = 5'd0;
        wr_data = 32'hFFFFFFFF;
        wr_en = 1;
        #10;
        wr_en = 0;
        rs1 = 5'd0;
        #10;
        $display("  Read x0: 0x%08x (expected 0x00000000)", rd_data1);
        if (rd_data1 == 32'd0) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 4: Read two different registers simultaneously
        $display("\nTEST 4: Read x5 and x10 simultaneously");
        rs1 = 5'd5; rs2 = 5'd10; #10;
        $display("  x5=0x%08x, x10=%d (expected 0xDEADBEEF, 100)", rd_data1, rd_data2);
        if (rd_data1 == 32'hDEADBEEF && rd_data2 == 32'd100)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        
        // TEST 5: Write to x15 first, then try to overwrite without wr_en
        $display("\nTEST 5: Write without wr_en (should be ignored)");
        // First write a known value
        rd = 5'd15;
        wr_data = 32'hAAAAAAAA;
        wr_en = 1;
        #10;
        // Now try to write without wr_en
        wr_data = 32'h12345678;
        wr_en = 0; // disabled
        #10;
        rs1 = 5'd15;
        #10;
        $display("  Read x15: 0x%08x (expected 0xAAAAAAAA - write ignored)", rd_data1);
        if (rd_data1 == 32'hAAAAAAAA) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 6: Overwrite existing register
        $display("\nTEST 6: Overwrite x5 with new value");
        rd = 5'd5;
        wr_data = 32'hCAFEBABE;
        wr_en = 1;
        #10;
        wr_en = 0;
        rs1 = 5'd5;
        #10;
        $display("  Read x5: 0x%08x (expected 0xCAFEBABE)", rd_data1);
        if (rd_data1 == 32'hCAFEBABE) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 7: Test all saved state registers (x1-x15)
        $display("\nTEST 7: Write pattern to x1-x15");
        wr_en = 1;
        for (integer i = 1; i <= 15; i = i + 1) begin
            rd = i;
            wr_data = i * 1000;
            #10;
        end
        wr_en = 0;
        #10;
        
        // Verify
        $display("  Verifying x1-x15:");
        for (integer i = 1; i <= 15; i = i + 1) begin
            rs1 = i;
            #10;
            if (rd_data1 == i * 1000)
                $display("    x%0d = %d ✓", i, rd_data1);
            else
                $display("    x%0d = %d ✗ (expected %d)", i, rd_data1, i*1000);
        end
        
        $display("\n=== Verification Complete ===\n");
        $finish;
    end
endmodule
