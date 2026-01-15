`timescale 1ns / 1ps

module data_mem_tb;

    reg         clk;
    reg         memwrite;
    reg         memread;
    reg  [2:0]  funct3;
    reg  [31:0] addr;
    reg  [31:0] writedata;
    wire [31:0] readdata;

    // Test parameters
    localparam LB  = 3'b000;
    localparam LH  = 3'b001;
    localparam LW  = 3'b010;
    localparam LBU = 3'b100;
    localparam LHU = 3'b101;
    localparam SB  = 3'b000;
    localparam SH  = 3'b001;
    localparam SW  = 3'b010;

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
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("data_mem_tb.vcd");
        $dumpvars(0, data_mem_tb);
        
        memread = 1'b0;
        memwrite = 1'b0;
        addr = 32'b0;
        writedata = 32'b0;
        funct3 = 3'b0;
        
        // Test Word Write (SW) and Read (LW)
        addr = 32'd0;
        writedata = 32'hDEADBEEF;
        funct3 = SW;
        memwrite = 1'b1;
        #10;
        memwrite = 1'b0;
        
        funct3 = LW;
        memread = 1'b1;
        #10 $display("Word Write/Read: wrote 0x%x, read 0x%x (expected 0xDEADBEEF)", writedata, readdata);
        memread = 1'b0;
        
        // Test Byte Write (SB) and Signed Byte Read (LB)
        addr = 32'd4;
        writedata = 32'h000000FF;
        funct3 = SB;
        memwrite = 1'b1;
        #10;
        writedata = 32'h00000055;
        #10;
        writedata = 32'h000000AA;
        #10;
        memwrite = 1'b0;
        
        // Read byte 0
        addr = 32'd4;
        funct3 = LB;
        memread = 1'b1;
        #10 $display("Byte Read [0]: read 0x%x (last byte written: 0xAA)", readdata);
        
        // Test Halfword Write (SH) and Read (LH)
        addr = 32'd8;
        writedata = 32'hDEADBEEF;
        funct3 = SH;
        memwrite = 1'b1;
        #10;
        memwrite = 1'b0;
        
        funct3 = LH;
        memread = 1'b1;
        #10 $display("Halfword Read: read 0x%x (expected 0x%x)", readdata, 32'hFFFFBEEF);
        memread = 1'b0;
        
        // Test Unsigned Byte Read (LBU)
        addr = 32'd4;
        funct3 = LBU;
        memread = 1'b1;
        #10 $display("Unsigned Byte Read: read 0x%x (expected 0x000000AA)", readdata);
        
        // Test Unsigned Halfword Read (LHU)
        addr = 32'd8;
        funct3 = LHU;
        #10 $display("Unsigned Halfword Read: read 0x%x (expected 0x0000BEEF)", readdata);
        memread = 1'b0;
        
        // Test different byte offsets
        addr = 32'd12;
        writedata = 32'h11223344;
        funct3 = SW;
        memwrite = 1'b1;
        #10;
        memwrite = 1'b0;
        
        // Read from different byte offsets
        addr = 32'd13; // Byte offset 1
        funct3 = LBU;
        memread = 1'b1;
        #10 $display("Byte offset 1: read 0x%x (expected 0x33)", readdata);
        
        addr = 32'd14; // Byte offset 2
        #10 $display("Byte offset 2: read 0x%x (expected 0x22)", readdata);
        
        addr = 32'd15; // Byte offset 3
        #10 $display("Byte offset 3: read 0x%x (expected 0x11)", readdata);
        memread = 1'b0;
        
        // Test simultaneous read/write (shouldn't happen but test anyway)
        addr = 32'd16;
        writedata = 32'hCAFEBABE;
        funct3 = SW;
        memwrite = 1'b1;
        memread = 1'b1;
        #10;
        memwrite = 1'b0;
        memread = 1'b0;
        
        $finish;
    end

endmodule
