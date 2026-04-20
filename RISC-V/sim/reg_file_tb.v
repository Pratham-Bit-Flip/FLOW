`timescale 1ns/100ps

module reg_file_tb;

    reg clk, wr_en;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] wr_data;
    wire [31:0] rd_data1, rd_data2;

    // DUT
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

    // clock toggle
    always #5 clk = ~clk;

    initial begin
        // wave dump
        $dumpfile("reg_file_tb.vcd");
        $dumpvars(0, reg_file_tb);
        
        $monitor("clk=%b | wr_en=%b | rs1=%0d->%0d | rs2=%0d->%0d | rd=%0d | wr_data=%0d",
         clk, wr_en, rs1, rd_data1, rs2, rd_data2, rd, wr_data);
        // initialization
        clk = 0; wr_en = 0;rs1 = 0; rs2 = 0; rd = 0;wr_data = 0;
        #10;
        // write into reg1
        wr_en = 1; rd = 5'd1; wr_data = 32'd15;
        #10; 
        wr_en = 0;
        #10;
        // read from reg1 and reg0
        rs1 = 5'd1; rs2 = 5'd0;
        #10;
        // write into reg5
        wr_en = 1; rd = 5'd5; wr_data = 32'd100;
        #10; 
        wr_en = 0;
        #10;
        // read reg5 and reg1
        rs1 = 5'd5; rs2 = 5'd1;
        #10;
        $finish;

    end
endmodule

