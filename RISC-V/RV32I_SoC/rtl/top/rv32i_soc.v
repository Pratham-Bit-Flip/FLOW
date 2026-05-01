// Generic SoC wrapper around the RV32I RTL.
// No board-specific wiring and no board-demo blink logic here.
module rv32i_soc (
    input  wire       clk,
    input  wire       reset_n,
    input  wire       uart_rx,
    output wire       uart_tx,
    output wire [7:0] led_soc
);
    wire reset = ~reset_n;

    riscv_top #(
        .CLK_HZ(100_000_000),
        .WITH_UART_BOOT(1'b1),
        .WITH_FLASH(1'b0)
    ) core (
        .clk(clk),
        .reset(reset),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .pc_out(),
        .instr_out(),
        .alu_result_out(),
        .reg_rs1_out(),
        .reg_rs2_out(),
        .wb_data_out(),
        .led_out(led_soc)
    );
endmodule