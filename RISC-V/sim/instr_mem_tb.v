`timescale 1ns / 1ps

module instr_mem_tb;

    reg  [31:0] pc;
    wire [31:0] instr;

    instr_mem uut (
        .pc(pc),
        .instr(instr)
    );

    initial begin
        $dumpfile("instr_mem_tb.vcd");
        $dumpvars(0, instr_mem_tb);
        
        // Test instruction at address 0
        // memory[0] = ADDI x1, x0, 5
        pc = 32'h00000000;
        #10 $display("Address 0: instr = 0x%x (expected 0x00500093 - ADDI x1, x0, 5)", instr);
        
        // Test instruction at address 4 (word address 1)
        // memory[1] = ADDI x2, x0, 10
        pc = 32'h00000004;
        #10 $display("Address 4: instr = 0x%x (expected 0x00A00113 - ADDI x2, x0, 10)", instr);
        
        // Test instruction at address 8 (word address 2)
        // memory[2] = ADD x3, x1, x2
        pc = 32'h00000008;
        #10 $display("Address 8: instr = 0x%x (expected 0x002081B3 - ADD x3, x1, x2)", instr);
        
        // Test instruction at address 12 (word address 3 and beyond - NOP)
        pc = 32'h0000000C;
        #10 $display("Address 12: instr = 0x%x (expected 0x00000013 - NOP)", instr);
        
        // Test with higher address (still NOP)
        pc = 32'h000001F0; // Address 496, word address 124
        #10 $display("Address 496: instr = 0x%x (expected 0x00000013 - NOP)", instr);
        
        // Test with offset - only lower 10 bits matter for word index (0-255)
        pc = 32'h00000010; // Word address 4
        #10 $display("Address 16: instr = 0x%x (expected 0x00000013 - NOP)", instr);
        
        $finish;
    end

endmodule
