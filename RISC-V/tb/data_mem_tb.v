`timescale 1ns / 1ps

module data_mem_tb;
    reg clk;
    reg memwrite;
    reg memread;
    reg [31:0] addr;
    reg [31:0] writedata;
    wire [31:0] readdata;

    data_mem uut (
        .clk(clk),
        .memwrite(memwrite),
        .memread(memread),
        .addr(addr),
        .writedata(writedata),
        .readdata(readdata)
    );

    always #5 clk = ~clk;

    initial begin
       $dumpfile("data_mem_tb.vcd");
       $dumpvars(0, data_mem_tb);
       
       clk = 0; memwrite = 0; memread = 0; addr = 0; writedata = 0;

       $readmemh("memory_init.hex", uut.memory);
       $display("Memory initialized from memory_init.hex");
       
       #10;
       memwrite = 1;
       addr = 32'h00000004; writedata = 32'hDEADBEEF; #10;
       addr = 32'h00000008; writedata = 32'h12345678; #10;
       addr = 32'h0000000C; writedata = 32'hCAFEBABE; #10;
       memwrite = 0;

       memread = 1;
       addr = 32'h00000004; #10;
       $display("Read @0x04 = %h", readdata);
       addr = 32'h00000008; #10;
       $display("Read @0x08 = %h", readdata);
       addr = 32'h0000000C; #10;
       $display("Read @0x0C = %h", readdata);
       memread = 0;

       $writememh("memory_dump.hex", uut.memory);
       $display("Memory contents dumped to memory_dump.hex");

       #20; $finish;
    end
endmodule
