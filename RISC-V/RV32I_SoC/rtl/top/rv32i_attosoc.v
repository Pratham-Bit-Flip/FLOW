// PicoRV-style SoC wrapper for the RV32I core.
// Keeps base core RTL unchanged and exposes a simple board-facing interface.
module rv32i_attosoc (
    input           clk,
    output wire [7:0] led,
    output wire       uart_tx,
    input           uart_rx
);
    reg [15:0] reset_cnt = 16'd0;
    wire resetn = &reset_cnt;

    (* keep = "true" *) wire [7:0]  led_mmio;
    (* keep = "true" *) wire [31:0] pc_dbg;

    always @(posedge clk) begin
        if (!resetn)
            reset_cnt <= reset_cnt + 16'd1;
    end

    (* keep_hierarchy = "yes" *) riscv_top #(
        .CLK_HZ(100_000_000),
        .WITH_UART_BOOT(1'b0),
        .WITH_FLASH(1'b0)
    ) cpu (
        .clk(clk),
        .reset(~resetn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .pc_out(pc_dbg),
        .instr_out(),
        .alu_result_out(),
        .reg_rs1_out(),
        .reg_rs2_out(),
        .wb_data_out(),
        .led_out(led_mmio)
    );

    // Keep user MMIO LED behavior and add a heartbeat from CPU PC activity.
    assign led = led_mmio ^ pc_dbg[24:17];
endmodule
