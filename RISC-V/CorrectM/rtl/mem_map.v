// mem_map.v - simple MMIO + RAM + flash mapping
module mem_map #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer UART_BAUD = 115200,
    parameter         WITH_FLASH = 1'b1,
    parameter integer DMEM_WORDS = 256,
    parameter integer FLASH_WORDS = 256,
    parameter         FLASH_INIT_FILE = "flash.hex",
    parameter integer FLASH_INIT_WORDS = 1
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        memwrite,
    input  wire        memread,
    input  wire [2:0]  funct3,
    input  wire [31:0] addr,
    input  wire [31:0] writedata,
    output reg  [31:0] readdata,
    output reg  [7:0]  led_out,
    output wire        uart_tx,
    input  wire        uart_rx
);
    // Address map
    localparam [31:0] RAM_BASE   = 32'h0000_0000; // 1KB RAM (0x0000_0000 - 0x0000_03FF)
    localparam [31:0] UART_BASE  = 32'h8000_0000; // UART registers
    localparam [31:0] LED_ADDR   = 32'h8000_1000; // LED MMIO
    localparam [31:0] FLASH_BASE = 32'h9000_0000; // Flash window

    wire is_ram   = (addr[31:10] == RAM_BASE[31:10]);
    wire is_uart  = (addr[31:8]  == UART_BASE[31:8]);
    wire is_led   = (addr == LED_ADDR);
    wire is_flash = (addr[31:16] == FLASH_BASE[31:16]);

    wire [31:0] ram_rdata;
    wire [31:0] uart_rdata;
    wire [31:0] flash_rdata;

    data_mem #(
        .WORDS(DMEM_WORDS)
    ) U_RAM (
        .clk(clk),
        .memwrite(memwrite && is_ram),
        .memread(memread && is_ram),
        .funct3(funct3),
        .addr(addr),
        .writedata(writedata),
        .readdata(ram_rdata)
    );

    uart_mmio #(.CLK_HZ(CLK_HZ), .BAUD(UART_BAUD)) U_UART (
        .clk(clk),
        .reset(reset),
        .memwrite(memwrite && is_uart),
        .memread(memread && is_uart),
        .addr(addr),
        .writedata(writedata),
        .readdata(uart_rdata),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );

    generate
        if (WITH_FLASH) begin : gen_flash
            flash_mem #(
                .WORDS(FLASH_WORDS),
                .INIT_FILE(FLASH_INIT_FILE),
                .INIT_WORDS(FLASH_INIT_WORDS)
            ) U_FLASH (
                .clk(clk),
                .memwrite(memwrite && is_flash),
                .memread(memread && is_flash),
                .funct3(funct3),
                .addr(addr),
                .writedata(writedata),
                .readdata(flash_rdata)
            );
        end else begin : gen_no_flash
            assign flash_rdata = 32'b0;
        end
    endgenerate

    always @(posedge clk) begin
        if (reset)
            led_out <= 8'd0;
        else if (memwrite && is_led)
            led_out <= writedata[7:0];
    end

    always @(*) begin
        if (memread) begin
            if (is_ram)
                readdata = ram_rdata;
            else if (is_uart)
                readdata = uart_rdata;
            else if (is_led)
                readdata = {24'b0, led_out};
            else if (is_flash)
                readdata = flash_rdata;
            else
                readdata = 32'b0;
        end else begin
            readdata = 32'b0;
        end
    end
endmodule
