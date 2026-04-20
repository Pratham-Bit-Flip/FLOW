// uart_bootloader.v - UART download to instruction RAM then release CPU
module uart_bootloader #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer BAUD   = 115200
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        uart_rx,

    output reg         boot_we,
    output reg  [31:0] boot_addr,
    output reg  [31:0] boot_wdata,
    output reg         boot_done
);
    // Protocol: [len:4 bytes LE][entry:4 bytes LE][payload bytes]

    localparam [3:0]
        S_LEN0  = 4'd0,
        S_LEN1  = 4'd1,
        S_LEN2  = 4'd2,
        S_LEN3  = 4'd3,
        S_ENT0  = 4'd4,
        S_ENT1  = 4'd5,
        S_ENT2  = 4'd6,
        S_ENT3  = 4'd7,
        S_LOAD  = 4'd8,
        S_DONE  = 4'd9;

    reg [3:0]  state;
    reg [31:0] image_len;
    reg [31:0] entry_addr;
    reg [31:0] byte_count;
    reg [31:0] word_buf;
    reg [1:0]  byte_idx;
    reg [31:0] word_buf_next;
    reg [31:0] byte_count_next;
    reg [1:0]  byte_idx_next;
    reg [31:0] word_base_addr;

    wire [7:0] rx_data;
    wire       rx_valid;
    reg        rx_clear;

    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) U_BOOT_RX (
        .clk(clk),
        .reset(reset),
        .rx(uart_rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_clear(rx_clear)
    );

    function [31:0] jal_x0;
        input [31:0] offset;
        reg [31:0] instr;
        begin
            instr = 32'b0;
            instr[6:0]   = 7'b1101111; // JAL
            instr[11:7]  = 5'd0;
            instr[19:12] = offset[19:12];
            instr[20]    = offset[11];
            instr[30:21] = offset[10:1];
            instr[31]    = offset[20];
            jal_x0 = instr;
        end
    endfunction

    wire entry_aligned = (entry_addr[0] == 1'b0);
    wire entry_in_range = (entry_addr[31:21] == 11'b0) || (entry_addr[31:21] == 11'h7FF);
    wire patch_needed = (entry_addr != 32'b0) && entry_aligned && entry_in_range;

    reg rx_valid_d;
    wire rx_pulse = rx_valid && !rx_valid_d;

    always @(posedge clk) begin
        if (reset) begin
            state        <= S_LEN0;
            image_len    <= 32'd0;
            entry_addr   <= 32'd0;
            byte_count   <= 32'd0;
            word_buf     <= 32'd0;
            byte_idx     <= 2'd0;
            boot_we      <= 1'b0;
            boot_addr    <= 32'd0;
            boot_wdata   <= 32'd0;
            boot_done    <= 1'b0;
            rx_clear   <= 1'b0;
            rx_valid_d <= 1'b0;
        end else begin
            boot_we   <= 1'b0;
            rx_clear  <= 1'b0;
            rx_valid_d <= rx_valid;

            if (!boot_done && rx_pulse) begin
                rx_clear <= 1'b1;
                case (state)
                    S_LEN0: begin image_len[7:0]   <= rx_data; state <= S_LEN1; end
                    S_LEN1: begin image_len[15:8]  <= rx_data; state <= S_LEN2; end
                    S_LEN2: begin image_len[23:16] <= rx_data; state <= S_LEN3; end
                    S_LEN3: begin image_len[31:24] <= rx_data; state <= S_ENT0; end

                    S_ENT0: begin entry_addr[7:0]   <= rx_data; state <= S_ENT1; end
                    S_ENT1: begin entry_addr[15:8]  <= rx_data; state <= S_ENT2; end
                    S_ENT2: begin entry_addr[23:16] <= rx_data; state <= S_ENT3; end
                    S_ENT3: begin entry_addr[31:24] <= rx_data; state <= S_LOAD; end
                    default: state <= state;
                endcase
            end

            if (!boot_done && rx_pulse && state == S_LOAD) begin
                word_buf_next = word_buf;
                word_buf_next[byte_idx*8 +: 8] = rx_data;
                byte_count_next = byte_count + 32'd1;
                byte_idx_next = byte_idx + 2'd1;
                word_base_addr = (byte_count - byte_idx);

                if (byte_idx == 2'd3) begin
                    boot_addr  <= word_base_addr;
                    boot_wdata <= word_buf_next;
                    boot_we    <= 1'b1;
                    byte_idx_next = 2'd0;
                end

                word_buf   <= word_buf_next;
                byte_count <= byte_count_next;
                byte_idx   <= byte_idx_next;

                if (byte_count_next >= image_len) begin
                    if (byte_idx != 2'd3) begin
                        boot_addr  <= word_base_addr;
                        boot_wdata <= word_buf_next;
                        boot_we    <= 1'b1;
                    end

                    if (patch_needed) begin
                        boot_addr  <= 32'd0;
                        boot_wdata <= jal_x0(entry_addr);
                        boot_we    <= 1'b1;
                    end

                    boot_done <= 1'b1;
                    state     <= S_DONE;
                end
            end
        end
    end
endmodule
