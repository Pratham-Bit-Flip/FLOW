module data_mem(
    input  wire        clk,
    input  wire        memwrite,      // write enable
    input  wire        memread,       // read enable
    input  wire [2:0]  funct3,        // operation type (NEW)
    input  wire [31:0] addr,          // byte address
    input  wire [31:0] writedata,     // data to write
    output reg  [31:0] readdata       // data to read
);
    reg [31:0] memory [0:255];

    // Word index and byte offset
    wire [7:0]  word_idx   = addr[9:2];
    wire [1:0]  byte_off   = addr[1:0];
    wire [31:0] mem_word   = memory[word_idx];

    // funct3 encoding:
    // 000 = LB/SB,  001 = LH/SH,  010 = LW/SW
    // 100 = LBU,    101 = LHU

    //================== WRITE (Store) ==================
    always @(posedge clk) begin
        if (memwrite) begin
            case (funct3[1:0])
                2'b00: begin // SB - Store Byte
                    case (byte_off)
                        2'b00: memory[word_idx][7:0]   <= writedata[7:0];
                        2'b01: memory[word_idx][15:8]  <= writedata[7:0];
                        2'b10: memory[word_idx][23:16] <= writedata[7:0];
                        2'b11: memory[word_idx][31:24] <= writedata[7:0];
                    endcase
                end
                2'b01: begin // SH - Store Halfword
                    case (byte_off[1])
                        1'b0: memory[word_idx][15:0]  <= writedata[15:0];
                        1'b1: memory[word_idx][31:16] <= writedata[15:0];
                    endcase
                end
                2'b10: begin // SW - Store Word
                    memory[word_idx] <= writedata;
                end
                default: memory[word_idx] <= writedata;
            endcase
        end
    end

    //================== READ (Load) ==================
    always @(*) begin
        if (memread) begin
            case (funct3)
                3'b000: begin // LB - Load Byte (signed)
                    case (byte_off)
                        2'b00: readdata = {{24{mem_word[7]}},  mem_word[7:0]};
                        2'b01: readdata = {{24{mem_word[15]}}, mem_word[15:8]};
                        2'b10: readdata = {{24{mem_word[23]}}, mem_word[23:16]};
                        2'b11: readdata = {{24{mem_word[31]}}, mem_word[31:24]};
                    endcase
                end
                3'b001: begin // LH - Load Halfword (signed)
                    case (byte_off[1])
                        1'b0: readdata = {{16{mem_word[15]}}, mem_word[15:0]};
                        1'b1: readdata = {{16{mem_word[31]}}, mem_word[31:16]};
                    endcase
                end
                3'b010: begin // LW - Load Word
                    readdata = mem_word;
                end
                3'b100: begin // LBU - Load Byte Unsigned
                    case (byte_off)
                        2'b00: readdata = {24'b0, mem_word[7:0]};
                        2'b01: readdata = {24'b0, mem_word[15:8]};
                        2'b10: readdata = {24'b0, mem_word[23:16]};
                        2'b11: readdata = {24'b0, mem_word[31:24]};
                    endcase
                end
                3'b101: begin // LHU - Load Halfword Unsigned
                    case (byte_off[1])
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
