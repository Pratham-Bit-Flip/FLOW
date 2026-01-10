module data_mem(
    input  wire clk,
    input  wire memwrite,   // write enable
    input  wire memread,   // read enable
    input  wire [31:0] addr,  // byte address
    input  wire [31:0] writedata, // data to write
    output reg  [31:0] readdata  // data to read
);
    reg [31:0] memory [0:255];   

    always @(posedge clk) begin
        if (memwrite)
            memory[addr[9:2]] <= writedata;  // word-aligned write
    end

    always @(*) begin
        if (memread)
            readdata = memory[addr[9:2]];    // word-aligned read
        else
            readdata = 32'b0;
    end
endmodule
