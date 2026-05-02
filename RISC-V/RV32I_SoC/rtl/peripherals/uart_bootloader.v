// uart_bootloader.v - Raw UART download to instruction RAM then release CPU
module uart_bootloader #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer BAUD   = 115200
) (
    input          clk,
    input          reset,
    input          uart_rx,

    output reg         boot_we,
    output reg  [31:0] boot_addr,
    output reg  [31:0] boot_wdata,
    output reg         boot_done,
    output reg         rx_byte_seen
);
    // Protocol: raw payload bytes only.
    // The host sends the firmware image directly; the loader writes sequentially
    // from address 0 and declares completion after the line goes idle.

    reg [31:0] byte_count;
    reg [31:0] word_buf;
    reg [1:0]  byte_idx;
    reg        saw_data;
    reg [31:0] rx_idle_cnt;
    reg [31:0] word_buf_next;
    reg [31:0] byte_count_next;
    reg [1:0]  byte_idx_next;
    reg [31:0] total_boot_timeout;

    // Wait long enough to cover packet transmission, then use idle as end-of-image.
    localparam integer RX_IDLE_TIMEOUT_CYCLES = (CLK_HZ / 20); // ~50ms
    localparam integer TOTAL_BOOT_TIMEOUT_CYCLES = (CLK_HZ * 1); // 1 second - fallback to allow CPU to run even if UART not connected

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

    reg rx_valid_d;
    wire rx_pulse = rx_valid && !rx_valid_d;

    always @(posedge clk) begin
        if (reset) begin
            byte_count   <= 32'd0;
            word_buf     <= 32'd0;
            byte_idx     <= 2'd0;
            saw_data     <= 1'b0;
            rx_idle_cnt  <= 32'd0;
            total_boot_timeout <= 32'd0;
            boot_we      <= 1'b0;
            boot_addr    <= 32'd0;
            boot_wdata   <= 32'd0;
            boot_done    <= 1'b0;
            rx_byte_seen <= 1'b0;
            rx_clear     <= 1'b0;
            rx_valid_d   <= 1'b0;
        end else begin
            boot_we   <= 1'b0;
            rx_clear  <= 1'b0;
            rx_valid_d <= rx_valid;

            if (!boot_done) begin
                // Increment global timeout counter
                total_boot_timeout <= total_boot_timeout + 32'd1;

                // Check for global timeout FIRST (always works, even if no data received)
                if (total_boot_timeout >= TOTAL_BOOT_TIMEOUT_CYCLES) begin
                    boot_done <= 1'b1;
                end
                // Otherwise handle normal UART RX logic
                else if (rx_pulse) begin
                    rx_idle_cnt <= 32'd0;
                    saw_data   <= 1'b1;
                end else if (saw_data) begin
                    if (rx_idle_cnt >= RX_IDLE_TIMEOUT_CYCLES) begin
                        if (byte_idx != 2'd0) begin
                            boot_addr  <= byte_count - byte_idx;
                            boot_wdata <= word_buf;
                            boot_we    <= 1'b1;
                        end
                        boot_done  <= 1'b1;
                    end else begin
                        rx_idle_cnt <= rx_idle_cnt + 32'd1;
                    end
                end
            end

            if (!boot_done && rx_pulse) begin
                rx_clear <= 1'b1;
                rx_byte_seen <= 1'b1;
                word_buf_next   = word_buf;
                byte_count_next = byte_count + 32'd1;
                byte_idx_next   = byte_idx + 2'd1;
                word_buf_next[byte_idx*8 +: 8] = rx_data;

                if (byte_idx == 2'd3) begin
                    boot_addr  <= byte_count - 32'd3;
                    boot_wdata <= word_buf_next;
                    boot_we    <= 1'b1;
                    word_buf_next = 32'd0;
                    byte_idx_next = 2'd0;
                end else begin
                    boot_we <= 1'b0;
                end

                word_buf   <= word_buf_next;
                byte_count <= byte_count_next;
                byte_idx   <= byte_idx_next;
            end
        end
    end
endmodule
