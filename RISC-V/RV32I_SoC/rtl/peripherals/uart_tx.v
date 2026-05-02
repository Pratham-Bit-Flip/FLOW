// uart_tx.v - 8N1 UART transmitter
module uart_tx #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer BAUD   = 115200
) (
    input         clk,
    input         reset,
    input         tx_start,
    input  [7:0] tx_data,
    output reg        tx,
    output wire       tx_busy
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

    assign tx_busy = (state != S_IDLE);

    always @(posedge clk) begin
        if (reset) begin
            state   <= S_IDLE;
            clk_cnt <= 13'd0;
            bit_idx <= 3'd0;
            shifter <= 8'd0;
            tx       <= 1'b1;
        end else begin
            case (state)
                S_IDLE: begin
                    tx <= 1'b1;
                    clk_cnt <= 13'd0;
                    bit_idx <= 3'd0;
                    if (tx_start) begin
                        shifter <= tx_data;
                        state   <= S_START;
                    end
                end

                S_START: begin
                    tx <= 1'b0; // start bit
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 13'd0;
                        state   <= S_DATA;
                    end else begin
                        clk_cnt <= clk_cnt + 13'd1;
                    end
                end

                S_DATA: begin
                    tx <= shifter[bit_idx];
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 13'd0;
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
                    tx <= 1'b1; // stop bit
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 13'd0;
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
