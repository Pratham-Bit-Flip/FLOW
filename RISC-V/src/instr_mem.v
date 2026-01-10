module instr_mem(
    input  wire [31:0] pc,      // Program counter
    output reg  [31:0] instr
);
    reg [31:0] memory [0:255];    // 256 words (1 KB)


    always @(*) begin
        instr = memory[pc[9:2]]; // word-aligned (2 LSBs zero)
    end
endmodule
