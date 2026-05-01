// Generic RV32I SoC wrapper with UART Bootloader
// Instantiates full RV32I core with MMIO LED + FT2232HL USB UART for dynamic firmware loading
//
// UART: 115200 baud, 8N1 format
// Bootloader: Waits for firmware via UART (50ms idle timeout or 1 second absolute)
// After timeout, CPU is released from reset and executes firmware from instruction memory
//
// LED[7] = hardware heartbeat (~1Hz blink, FPGA-alive indicator)
// LED[6] = UART line activity pulse (short stretch on detected start bit)
// LED[5] = decoded UART byte seen by bootloader (indicates RX activity)
// LED[4] = boot_done from bootloader (CPU released from reset)
// LED[3:0] = firmware MMIO (application-controlled)
//
// GPIO Pins:
// J21 = uart_rx (from FT2232HL)
// K22 = uart_tx (to FT2232HL)

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
    wire       boot_done_dbg;
    wire       cpu_running_dbg;
    wire       boot_rx_seen_dbg;

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
        .WITH_UART_BOOT(1'b1),  // Enable UART bootloader for dynamic firmware upload via FT2232HL
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
        .led_out(led_mmio),
        .boot_done_out(boot_done_dbg),
        .cpu_running_out(cpu_running_dbg),
        .boot_rx_seen_out(boot_rx_seen_dbg)
    );

    // UART RX activity detector for hardware bring-up/debug.
    reg [1:0] rx_sync = 2'b11;
    reg       rx_prev = 1'b1;
    reg [21:0] rx_activity_cnt = 22'd0;
    always @(posedge sys_clk) begin
        rx_sync <= {rx_sync[0], uart_rx};
        rx_prev <= rx_sync[1];
        if (rx_prev && !rx_sync[1]) begin
            rx_activity_cnt <= {22{1'b1}};
        end else if (rx_activity_cnt != 22'd0) begin
            rx_activity_cnt <= rx_activity_cnt - 22'd1;
        end
    end

    // LED mapping for diagnostics
    // Debug: hardcode LED5 and LED4 to test if we reach here
    assign led = {hb_cnt[25], (rx_activity_cnt != 22'd0), 1'b1, 1'b1, led_mmio[3:0]};
endmodule
