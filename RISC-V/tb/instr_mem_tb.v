`timescale 1ns/1ps

module instr_mem_tb;
    reg [31:0] pc;
    wire [31:0] instr;

    // Instantiation instr_mem
    instr_mem dut(.pc(pc),.instr(instr));
    reg [31:0] memory;

    initial begin
        // Waveform dump
        $dumpfile("instr_mem_tb.vcd");
        $dumpvars(0, instr_mem_tb);

        $monitor("time=%t | pc=%d | instr=0x%h | memory=0x%h", 
                 $time, pc, instr, memory);
        // Initialization
        pc = 0;
        memory = 32'h00500093; // ADDI x1, x0, 5
        #10;
        pc = 32'd4;  // next instruction
        memory = 32'h00A00113; // ADDI x2, x0, 10
        #10;
        pc = 32'd8;
        memory = 32'h002081B3; // ADD x3, x1, x2
        #10;
        $finish;
    end
endmodule
