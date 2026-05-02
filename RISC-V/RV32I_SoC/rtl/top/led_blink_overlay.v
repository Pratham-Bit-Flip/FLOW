// Board-demo LED blink overlay.
// This keeps blinking behavior out of base RTL and generic SoC modules.
module led_blink_overlay #(
    parameter integer DIV_BIT = 24
) (
    input         clk,
    input  [7:0] led_in,
    output wire [7:0] led_out
);
    reg [31:0] div_cnt = 32'd0;

    always @(posedge clk)
        div_cnt <= div_cnt + 32'd1;

    assign led_out = led_in ^ {8{div_cnt[DIV_BIT]}};
endmodule