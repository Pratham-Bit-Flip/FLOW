// Generic RV32I SoC wrapper
// Instantiates full RV32I core with MMIO LED + UART
//
// LED[7] = hardware heartbeat (~1Hz blink, FPGA-alive indicator)
// LED[6:0] = firmware MMIO (driven by CPU after UART boot)

module rv32i_led_top (
    input  wire       sys_clk,
    input  wire       sys_rst_n,
    input  wire       uart_rx,
    output wire       uart_tx,
    output wire [7:0] led
);
    reg [7:0] por_cnt = 8'd0;
    wire ext_reset = ~sys_rst_n;
    wire reset = (por_cnt != 8'hFF) | ext_reset;

    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] alu_result_out;
    wire [31:0] reg_rs1_out;
    wire [31:0] reg_rs2_out;
    wire [31:0] wb_data_out;
    wire [7:0] led_mmio;

    // Hold reset high for a short, deterministic POR window.
    always @(posedge sys_clk) begin
        if (por_cnt != 8'hFF)
            por_cnt <= por_cnt + 8'd1;
    end

    // Hardware heartbeat: ~1 Hz blink on LED[7], proves FPGA is alive
    // independent of CPU / UART bootloader.
    reg [25:0] hb_cnt = 26'd0;
    always @(posedge sys_clk)
        hb_cnt <= hb_cnt + 26'd1;

    riscv_top #(
        .WITH_UART_BOOT(1'b1),
        .WITH_FLASH    (1'b0)
    ) cpu (
        .clk(sys_clk),
        .reset(reset),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .alu_result_out(alu_result_out),
        .reg_rs1_out(reg_rs1_out),
        .reg_rs2_out(reg_rs2_out),
        .wb_data_out(wb_data_out),
        .led_out(led_mmio)
    );

    // UART RX activity detector: toggles LED[6] on each start bit
    // Proves whether data physically reaches FPGA pin J21 (uart_rx)
    reg [1:0] rx_sync = 2'b11;
    reg       rx_prev = 1'b1;
    reg       rx_activity = 1'b0;
    always @(posedge sys_clk) begin
        rx_sync <= {rx_sync[0], uart_rx};  // metastability sync
        rx_prev <= rx_sync[1];
        if (rx_prev && !rx_sync[1])        // falling edge = start bit
            rx_activity <= ~rx_activity;   // toggle on each byte
    end

    // LED[7] = hardware heartbeat (FPGA alive, no CPU needed)
    // LED[6] = UART RX activity (toggles per start bit received)
    // LED[5:0] = firmware MMIO (only active after UART boot completes)
    assign led = {hb_cnt[25], rx_activity, led_mmio[5:0]};
endmodule
