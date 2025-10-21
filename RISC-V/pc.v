 module pc (
    input  wire       clk,
    input  wire       rst,
	input wire [31:0] next_pc, // Next Cycle
    output reg [31:0] pc_current
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_current <= 32'h0000_0000;   // reset to 0
        else
            pc_current <= next_pc;     // next cycle
    end

endmodule

