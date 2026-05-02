module rv32i_versa5g_top (
    input         clkin,
    input         uart_rx,
    output wire       uart_tx,
    output wire [7:0] led
);
    reg [15:0] reset_cnt = 16'd0;
    wire reset_n = &reset_cnt;
    wire [7:0] led_soc;
    wire [7:0] led_blink;

    always @(posedge clkin) begin
        if (!reset_n)
            reset_cnt <= reset_cnt + 16'd1;
    end

    rv32i_soc soc (
        .clk(clkin),
        .reset_n(reset_n),
        .led_soc(led_soc),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );

    led_blink_overlay #(.DIV_BIT(24)) blink (
        .clk(clkin),
        .led_in(led_soc),
        .led_out(led_blink)
    );

    // Versa-5G LEDs are active-low in local board examples.
    assign led = ~led_blink;
endmodule