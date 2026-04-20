`timescale 1ns/1ps

module pc_tb;

reg clk ;
reg rst;
reg [31:0] next_pc;

wire [31:0] pc_current;

//Instantiation

pc dut(.clk(clk), .rst(rst), .next_pc(next_pc), .pc_current(pc_current));

 // clock toggle
    always #5 clk = ~clk;

    initial begin
        // wave dump
        $dumpfile("pc_tb.vcd");
        $dumpvars(0, pc_tb);
        
        $monitor("Time=%0t | clk=%b | rst=%b | next_pc=%h | pc_current=%b ",
         $time,clk, rst,next_pc,pc_current);
         
         // Initial
         clk=0;rst=0;next_pc=32'h0000_0000;
         #10;
         //Start rst /apply
         rst=1;next_pc=32'h0000_0004;
         #10;
         
         //Stop the rst
         rst=0;
         #10;
         
         // nest block 
         next_pc=32'h0000_0008;
         #10;
         
          next_pc=32'h0000_0012;
         #10;
         
          next_pc=32'h0000_0016;
         #10;
         
          next_pc=32'h0000_0020;
         #10;
         
         $finish;
end 
endmodule
