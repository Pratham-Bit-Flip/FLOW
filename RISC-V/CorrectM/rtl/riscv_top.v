//==========================
// RISC-V TOP MODULE
//==========================
module riscv_top #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer UART_BAUD = 115200,
    parameter         WITH_UART_BOOT = 1'b1,
    parameter         WITH_FLASH = 1'b1,
    parameter integer IMEM_WORDS = 1024,
    parameter integer DMEM_WORDS = 256,
    parameter integer FLASH_WORDS = 256,
    parameter         BOOTROM_FILE = "bootrom.hex",
    parameter integer BOOTROM_INIT_WORDS = 128,
    parameter         FLASH_INIT_FILE = "flash.hex",
    parameter integer FLASH_INIT_WORDS = 1
) (
    input  wire         clk,
    input  wire         reset,
    input  wire         uart_rx,
    output wire         uart_tx,
    
    // Debug / Monitoring outputs
    output wire [31:0]  pc_out,         // current PC value
    output wire [31:0]  instr_out,      // current instruction
    output wire [31:0]  alu_result_out, // ALU result
    output wire [31:0]  reg_rs1_out,    // source register 1 value
    output wire [31:0]  reg_rs2_out,    // source register 2 value
    output wire [31:0]  wb_data_out,    // final write-back data
    output wire [7:0]   led_out         // memory-mapped LED register
);

    //=========================================
    // UART Bootloader (loads instruction RAM)
    //=========================================
    wire        boot_we;
    wire [31:0] boot_addr;
    wire [31:0] boot_wdata;
    wire        boot_done;

    generate
        if (WITH_UART_BOOT) begin : gen_uart_boot
            uart_bootloader #(.CLK_HZ(CLK_HZ), .BAUD(UART_BAUD)) BOOT (
                .clk(clk),
                .reset(reset),
                .uart_rx(uart_rx),
                .boot_we(boot_we),
                .boot_addr(boot_addr),
                .boot_wdata(boot_wdata),
                .boot_done(boot_done)
            );
        end else begin : gen_boot_bypass
            assign boot_we = 1'b0;
            assign boot_addr = 32'b0;
            assign boot_wdata = 32'b0;
            assign boot_done = 1'b1;
        end
    endgenerate

    wire cpu_reset = reset | ~boot_done;

    //====================
    // Datapath + Memories
    //====================
    wire [31:0] imem_addr;
    wire [31:0] instr;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [31:0] data_mem_out;
    wire [2:0]  dmem_funct3;
    wire        dmem_we;
    wire        dmem_re;

    instr_mem #(
        .DEPTH(IMEM_WORDS),
        .BOOTROM_FILE(BOOTROM_FILE),
        .INIT_WORDS(BOOTROM_INIT_WORDS)
    ) IMEM (
        .clk(clk),
        .pc(imem_addr),
        .boot_we(boot_we),
        .boot_addr(boot_addr),
        .boot_wdata(boot_wdata),
        .instr(instr)
    );

    datapath CORE (
        .clk(clk),
        .rst(cpu_reset),
        .imem_addr(imem_addr),
        .imem_rdata(instr),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_rdata(data_mem_out),
        .dmem_funct3(dmem_funct3),
        .dmem_we(dmem_we),
        .dmem_re(dmem_re),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .alu_result_out(alu_result_out),
        .reg_rs1_out(reg_rs1_out),
        .reg_rs2_out(reg_rs2_out),
        .wb_data_out(wb_data_out)
    );

    mem_map #(
        .CLK_HZ(CLK_HZ),
        .UART_BAUD(UART_BAUD),
        .WITH_FLASH(WITH_FLASH),
        .DMEM_WORDS(DMEM_WORDS),
        .FLASH_WORDS(FLASH_WORDS),
        .FLASH_INIT_FILE(FLASH_INIT_FILE),
        .FLASH_INIT_WORDS(FLASH_INIT_WORDS)
    ) MEMMAP (
        .clk(clk),
        .reset(cpu_reset),
        .memwrite(dmem_we),
        .memread(dmem_re),
        .funct3(dmem_funct3),
        .addr(dmem_addr),
        .writedata(dmem_wdata),
        .readdata(data_mem_out),
        .led_out(led_out),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );

endmodule

