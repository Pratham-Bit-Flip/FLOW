// uart_mmio.v - memory-mapped UART (TX/RX)
module uart_mmio #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer BAUD   = 115200
) (
    input  wire       clk,
    input  wire       reset,

    input  wire        memwrite,
    input  wire        memread,
    input  wire [31:0] addr,
    input  wire [31:0] writedata,
    output reg  [31:0] readdata,

    output wire       uart_tx,
    input  wire       uart_rx
);
    // Register map (offsets)
    // 0x00 TXDATA (write)
    // 0x04 STATUS (read) [0]=tx_ready, [1]=rx_valid
    // 0x08 RXDATA (read)

    wire [3:0] reg_sel = addr[5:2];

    reg [7:0] tx_data_reg;
    reg       tx_start;
    wire      tx_busy;

    wire [7:0] rx_data;
    reg        rx_clear;
    wire       rx_valid;

    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) U_TX (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .tx_data(tx_data_reg),
        .tx(uart_tx),
        .tx_busy(tx_busy)
    );

    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) U_RX (
        .clk(clk),
        .reset(reset),
        .rx(uart_rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_clear(rx_clear)
    );

    always @(posedge clk) begin
        if (reset) begin
            tx_data_reg <= 8'd0;
            tx_start    <= 1'b0;
            rx_clear    <= 1'b0;
        end else begin
            tx_start <= 1'b0;
            rx_clear <= 1'b0;

            if (memwrite && (reg_sel == 4'h0)) begin
                if (!tx_busy) begin
                    tx_data_reg <= writedata[7:0];
                    tx_start    <= 1'b1;
                end
            end

            if (memread && (reg_sel == 4'h2)) begin
                rx_clear <= 1'b1;
            end
        end
    end

    always @(*) begin
        case (reg_sel)
            4'h0: readdata = {24'b0, tx_data_reg};
            4'h1: readdata = {30'b0, rx_valid, ~tx_busy};
            4'h2: readdata = {24'b0, rx_data};
            default: readdata = 32'b0;
        endcase
    end
endmodule
