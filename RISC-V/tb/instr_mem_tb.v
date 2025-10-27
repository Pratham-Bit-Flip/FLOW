`timescale 1ns/100ps

module instr_mem_tb;
 reg [31:0] pc;
 wire [31:0] instr;
 
 reg [31:0] memory [0:15];
 
 // Instantiation instr_mem
 
instr_mem dut(.pc(pc),.instr(instr));

initial begin
        // Waveform dump
        $dumpfile("instr_mem_tb.vcd");
        $dumpvars(0, instr_mem_tb);

        $monitor("time=%t | pc=%d | instr=%d", $time, pc,instr);
        
        //initialization
        pc=0;
        #10;
        
        pc=32'd4;  // for next intrstruction
        #10;
        
        pc=32'd8;
        #10;
        
        $finish;
end
endmodule
