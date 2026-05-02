// Numato Mimas A7 SoC Top
// Boots directly from bootrom (WITH_UART_BOOT=0) - market SoC style
// No UART host required: CPU starts running LED blink from ROM on power-up

module rv32i_numato_top (
    input  sys_clk,
    input         sys_rst_n,
    output wire [7:0] led
);
    reg [7:0] por_cnt = 8'd0;
    reg [31:0] hb_cnt = 32'd0;
    reg rst_sync_1 = 1'b0;
    reg rst_sync_2 = 1'b0;

    wire ext_reset = ~rst_sync_2;
    wire reset = ext_reset | (por_cnt != 8'hFF);
    wire uart_tx_unused;
    wire [7:0] led_mmio;
    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] alu_result_out;
    wire [31:0] reg_rs1_out;
    wire [31:0] reg_rs2_out;
    wire [31:0] wb_data_out;

    // Asynchronous assertion from button, synchronous release to sys_clk domain.
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rst_sync_1 <= 1'b0;
            rst_sync_2 <= 1'b0;
        end else begin
            rst_sync_1 <= 1'b1;
            rst_sync_2 <= rst_sync_1;
        end
    end

    // Universal reset hold: on any reset request, restart POR stretch window.
    always @(posedge sys_clk or posedge ext_reset) begin
        if (ext_reset)
            por_cnt <= 8'd0;
        else if (por_cnt != 8'hFF)
            por_cnt <= por_cnt + 8'd1;
    end

    always @(posedge sys_clk) begin
        hb_cnt <= hb_cnt + 32'd1;
    end

    riscv_top #(
        .WITH_UART_BOOT(1'b0),
        .WITH_FLASH    (1'b0)
    ) cpu (
        .clk            (sys_clk),
        .reset          (reset),
        .uart_rx        (1'b1),
        .uart_tx        (uart_tx_unused),
        .pc_out         (pc_out),
        .instr_out      (instr_out),
        .alu_result_out (alu_result_out),
        .reg_rs1_out    (reg_rs1_out),
        .reg_rs2_out    (reg_rs2_out),
        .wb_data_out    (wb_data_out),
        .led_out        (led_mmio)
    );

    assign led = {7'b0000000, (led_mmio[0] ^ hb_cnt[25])};
endmodule
