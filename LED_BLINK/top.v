module top(
    input  wire osc_clk,   // 50 MHz clock input
    input  wire PB_2,      // Push button, active low reset
    output wire LED_2      // LED output
);

    // Instantiate LED blinker
    led_blink led0 (
        .clk   (osc_clk),
        .rst_n (PB_2),
        .led   (LED_2)
    );

endmodule
