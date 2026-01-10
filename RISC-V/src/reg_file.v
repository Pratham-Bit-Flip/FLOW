module reg_file(
    input  wire  clk,
    input  wire  wr_en,           // write enable
    input  wire [4:0]  rs1, rs2, rd,  //source regs and destination reg
    input  wire [31:0] wr_data,           // write data
    output wire [31:0] rd_data1, rd_data2      // read data outputs
);
    reg [31:0] regs[0:31];           // 32 registers

    // Read (combinational)
    assign rd_data1 = (rs1 == 0) ? 32'b0 : regs[rs1];
    assign rd_data2 = (rs2 == 0) ? 32'b0 : regs[rs2];

    // Write (synchronous)
    always @(posedge clk) begin
        if (wr_en && rd != 0)
            regs[rd] <= wr_data;
    end
endmodule
