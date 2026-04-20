module instr_mem(
    input  clk,
    input [31:0] pc,
    input boot_we,
    input [31:0] boot_addr,
    input[31:0] boot_wdata,
    output reg[31:0] instr
);
    parameter integer DEPTH = 1024; // words (4KB) instruction space 
    parameter BOOTROM_FILE = "bootrom.hex";
    parameter integer INIT_WORDS = 128;

    localparam integer ADDR_W = $clog2(DEPTH); // bits needed to address DEPTH words
    reg [31:0] memory [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = 32'h00000013; // NOP is used for safety in case of out-of-bounds access
        $readmemh(BOOTROM_FILE, memory, 0, INIT_WORDS-1);
    end

    always @(posedge clk) begin
        if (boot_we) begin
            memory[boot_addr[ADDR_W+1:2]] <= boot_wdata; // basiically if boot_we is 1(high) write one word to the memory 
        end
    end

    always @(*) begin
        instr = memory[pc[ADDR_W+1:2]];
    end
endmodule
