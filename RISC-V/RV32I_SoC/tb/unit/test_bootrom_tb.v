`timescale 1ns / 1ps

module test_bootrom_tb;
    reg clk;
    reg [31:0] pc;
    reg boot_we;
    reg [31:0] boot_addr;
    reg [31:0] boot_wdata;
    wire [31:0] instr;
    
    // Instantiate instruction memory
    instr_mem uut (
        .clk(clk),
        .pc(pc),
        .boot_we(boot_we),
        .boot_addr(boot_addr),
        .boot_wdata(boot_wdata),
        .instr(instr)
    );
    
    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock
    
    integer i;
    
    initial begin
        // Generate waveform file
        $dumpfile("test_bootrom.vcd");
        $dumpvars(0, test_bootrom_tb);
        
        $display("\n=== BOOT ROM VERIFICATION TEST ===\n");
        
        // Initialize signals
        pc = 32'h00000000;
        boot_we = 0;
        boot_addr = 0;
        boot_wdata = 0;
        
        // Wait for boot ROM to load
        #10;
        
        // Read and display first 16 instructions
        $display("Reading first 16 instructions from boot ROM:\n");
        $display("Addr      | Hex Value  | Expected (from bootrom.hex)");
        $display("----------|------------|---------------------------");
        
        for (i = 0; i < 16; i = i + 1) begin
            pc = i * 4;
            #10;
            $display("0x%08x | 0x%08x | ", pc, instr);
        end
        
        $display("\n=== Verification Complete ===\n");
        
        // Check first few instructions match expected values
        pc = 32'h00000000; #10;
        if (instr == 32'h80000537)
            $display("✓ PASS: Instruction 0 = 0x80000537 (LUI x10, 0x80000)");
        else
            $display("✗ FAIL: Instruction 0 = 0x%08x (expected 0x80000537)", instr);
            
        pc = 32'h00000004; #10;
        if (instr == 32'h00100093)
            $display("✓ PASS: Instruction 1 = 0x00100093 (ADDI x1, x0, 1)");
        else
            $display("✗ FAIL: Instruction 1 = 0x%08x (expected 0x00100093)", instr);
            
        pc = 32'h0000001C; #10;
        if (instr == 32'hfc00006f)
            $display("✓ PASS: Instruction 7 = 0xfc00006f (JAL x0, -64)");
        else
            $display("✗ FAIL: Instruction 7 = 0x%08x (expected 0xfc00006f)", instr);
            
        pc = 32'h00000020; #10;
        if (instr == 32'h00000013)
            $display("✓ PASS: Instruction 8 = 0x00000013 (NOP padding)");
        else
            $display("✗ FAIL: Instruction 8 = 0x%08x (expected 0x00000013)", instr);
        
        $display("");
        $finish;
    end
endmodule
