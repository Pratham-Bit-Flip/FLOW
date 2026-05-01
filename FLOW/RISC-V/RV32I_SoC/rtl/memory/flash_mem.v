// flash_mem.v - simple memory-mapped flash model
module flash_mem #(
    parameter integer WORDS = 256,            // 1KB
    parameter         INIT_FILE = "init/flash.hex",
    parameter integer INIT_WORDS = 1
) (
    input  wire        clk,
    input  wire        memwrite,
    input  wire        memread,
    input  wire [2:0]  funct3,
    input  wire [31:0] addr,
    input  wire [31:0] writedata,
    output reg  [31:0] readdata
);
    localparam integer ADDR_W = (WORDS <= 2) ? 1 : $clog2(WORDS);
    (* ram_style = "block" *) reg [31:0] memory [0:WORDS-1];
    integer i;

    wire [ADDR_W-1:0] word_idx = addr[ADDR_W+1:2];
    wire [1:0]  byte_off = addr[1:0];
    reg  [31:0] mem_word;
    reg  [2:0]  funct3_q;
    reg  [1:0]  byte_off_q;
    reg         memread_q;

    initial begin
        for (i = 0; i < WORDS; i = i + 1)
            memory[i] = 32'h00000013; // NOP
        $readmemh(INIT_FILE, memory, 0, INIT_WORDS-1);
    end

    // BRAM-friendly synchronous access.
    // Writes are ignored in hardware-oriented builds because flash is treated as ROM.
    always @(posedge clk) begin
        if (memwrite) begin
            // Optional simulation-only flash patching path.
            // Keep full-word writes only to stay inference-friendly.
            if (funct3[1:0] == 2'b10)
                memory[word_idx] <= writedata;
        end

        mem_word  <= memory[word_idx];
        funct3_q  <= funct3;
        byte_off_q <= byte_off;
        memread_q <= memread;
    end

    always @(*) begin
        if (memread_q) begin
            case (funct3_q)
                3'b000: begin // LB
                    case (byte_off_q)
                        2'b00: readdata = {{24{mem_word[7]}},  mem_word[7:0]};
                        2'b01: readdata = {{24{mem_word[15]}}, mem_word[15:8]};
                        2'b10: readdata = {{24{mem_word[23]}}, mem_word[23:16]};
                        2'b11: readdata = {{24{mem_word[31]}}, mem_word[31:24]};
                    endcase
                end
                3'b001: begin // LH
                    case (byte_off_q[1])
                        1'b0: readdata = {{16{mem_word[15]}}, mem_word[15:0]};
                        1'b1: readdata = {{16{mem_word[31]}}, mem_word[31:16]};
                    endcase 
                end
                3'b010: readdata = mem_word; // LW
                3'b100: begin // LBU
                    case (byte_off_q)
                        2'b00: readdata = {24'b0, mem_word[7:0]};
                        2'b01: readdata = {24'b0, mem_word[15:8]};
                        2'b10: readdata = {24'b0, mem_word[23:16]};
                        2'b11: readdata = {24'b0, mem_word[31:24]};
                    endcase
                end
                3'b101: begin // LHU
                    case (byte_off_q[1])
                        1'b0: readdata = {16'b0, mem_word[15:0]};
                        1'b1: readdata = {16'b0, mem_word[31:16]};
                    endcase
                end
                default: readdata = mem_word;
            endcase
        end else begin
            readdata = 32'b0;
        end
    end
endmodule
