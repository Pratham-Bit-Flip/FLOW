// uart_rx.v - 8N1 UART receiver
module uart_rx #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer BAUD   = 115200
) (
    input clk,
    input  reset,
    input    rx,
    output reg  [7:0] rx_data,
    output reg        rx_valid,
    input    rx_clear
);
    localparam integer CLKS_PER_BIT = (CLK_HZ / BAUD);

    localparam [2:0]
        S_IDLE  = 3'd0,
        S_START = 3'd1,
        S_DATA  = 3'd2,
        S_STOP  = 3'd3;

    reg [2:0]  state;
    reg [12:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shifter;

    always @(posedge clk) begin
        if (reset) begin
            state    <= S_IDLE;
            clk_cnt  <= 13'd0;
            bit_idx  <= 3'd0;
            shifter  <= 8'd0;
            rx_data  <= 8'd0;
            rx_valid <= 1'b0;
        end else begin
            if (rx_clear)
                rx_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    clk_cnt <= 13'd0;
                    bit_idx <= 3'd0;
                    if (rx == 1'b0) begin
                        state <= S_START;
                    end
                end

                S_START: begin
                    if (clk_cnt == (CLKS_PER_BIT/2)) begin
                        if (rx == 1'b0) begin
                            clk_cnt <= 13'd0;
                            state   <= S_DATA;
                        end else begin
                            state <= S_IDLE; // false start
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 13'd1;
                    end
                end

                S_DATA: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 13'd0;
                        shifter[bit_idx] <= rx;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 3'd0;
                            state   <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 3'd1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 13'd1;
                    end
                end

                S_STOP: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 13'd0;
                        rx_data <= shifter;
                        rx_valid <= 1'b1;
                        state   <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 13'd1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
