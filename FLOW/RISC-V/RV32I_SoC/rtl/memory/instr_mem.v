module instr_mem(
    input  clk,
    input [31:0] pc,
    input boot_we,
    input [31:0] boot_addr,
    input[31:0] boot_wdata,
    output reg[31:0] instr
);
    parameter integer DEPTH = 256;
    parameter integer INIT_WORDS = 128;

    localparam integer ADDR_W = $clog2(DEPTH);
    
    // Separate RAM for bootloader writes
    reg [31:0] ram [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            ram[i] = 32'h00000013; // NOP
    end

    always @(posedge clk) begin
        if (boot_we) begin
            ram[boot_addr[ADDR_W+1:2]] <= boot_wdata;
        end
    end

    // Combinational ROM + RAM mux
    // ROM hardcodes first 8 instructions (ledtest firmware)
    always @(*) begin
        case (pc[ADDR_W+1:2])
            10'd0: instr = 32'h800017b7;   // lui x15, 0x80001 (LOAD UPPER)
            10'd1: instr = 32'h0ff00713;   // addi x14, x0, 0xff (x14 = 0xFF)
            10'd2: instr = 32'h00e7a023;   // sw x14, 0(x15) (WRITE 0xFF to LED @0x80001000)
            10'd3: instr = 32'h0000006f;   // jal x0, 0 (INFINITE LOOP - stay here forever)
            default: instr = ram[pc[ADDR_W+1:2]];
        endcase
    end
endmodule
