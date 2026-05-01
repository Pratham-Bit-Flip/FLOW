//==========================
// RISC-V TOP MODULE
//==========================
module riscv_top #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer UART_BAUD = 115200,
    parameter         WITH_UART_BOOT = 1'b0,
    parameter         WITH_FLASH = 1'b0,
    parameter integer IMEM_WORDS = 1024,
    parameter integer DMEM_WORDS = 256,
    parameter integer FLASH_WORDS = 256,
    parameter         BOOTROM_FILE = "bootrom.hex",
    parameter integer BOOTROM_INIT_WORDS = 128,
    parameter         FLASH_INIT_FILE = "init/flash.hex",
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
    output wire [7:0]   led_out,        // memory-mapped LED register
    output wire         boot_done_out,  // bootloader finished and CPU released
    output wire         cpu_running_out, // CPU reset deasserted
    output wire         boot_rx_seen_out // bootloader decoded at least one UART byte
);

    //=========================================
    // UART Bootloader (loads instruction RAM)
    //=========================================
    wire        boot_we;
    wire [31:0] boot_addr;
    wire [31:0] boot_wdata;
    wire        boot_done;
    wire        boot_rx_seen;

    generate
        if (WITH_UART_BOOT) begin : gen_uart_boot
            uart_bootloader #(.CLK_HZ(CLK_HZ), .BAUD(UART_BAUD)) BOOT (
                .clk(clk),
                .reset(reset),
                .uart_rx(uart_rx),
                .boot_we(boot_we),
                .boot_addr(boot_addr),
                .boot_wdata(boot_wdata),
                .boot_done(boot_done),
                .rx_byte_seen(boot_rx_seen)
            );
        end else begin : gen_boot_bypass
            assign boot_we = 1'b0;
            assign boot_addr = 32'b0;
            assign boot_wdata = 32'b0;
            assign boot_done = 1'b1;
            assign boot_rx_seen = 1'b0;
        end
    endgenerate

    assign boot_done_out = boot_done;
    assign boot_rx_seen_out = boot_rx_seen;

    wire cpu_reset = reset | ~boot_done;
    assign cpu_running_out = ~cpu_reset;

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

    //========== INLINE INSTRUCTION MEMORY (ROM + Bootloader RAM) ==========
    // This is INLINED here (not a separate module) so Yosys cannot delete it
    // as "unused module". Combinational case statement generates ROM logic.
    
    localparam integer IMEM_ADDR_W = $clog2(IMEM_WORDS);
    
    reg [31:0] bootrom_ram [0:IMEM_WORDS-1];
    integer boot_idx;
    initial begin
        for (boot_idx = 0; boot_idx < IMEM_WORDS; boot_idx = boot_idx + 1)
            bootrom_ram[boot_idx] = 32'h00000013; // NOP
    end
    
    // Bootloader write port (synchronous)
    always @(posedge clk) begin
        if (boot_we) begin
            bootrom_ram[boot_addr[IMEM_ADDR_W+1:2]] <= boot_wdata;
        end
    end
    
    // **INLINED** Combinational ROM + RAM mux
    // ROM hardcodes first 4 instructions (ledtest firmware)
    // Force synthesis with (keep) attribute - case statement won't be optimized away
    (* keep *)
    reg [31:0] instr_comb;
    
    always @(*) begin
        case (imem_addr[IMEM_ADDR_W+1:2])
            10'd0: instr_comb = 32'h800017b7;   // lui x15, 0x80001
            10'd1: instr_comb = 32'h0ff00713;   // addi x14, x0, 0xff
            10'd2: instr_comb = 32'h00e7a023;   // sw x14, 0(x15)
            10'd3: instr_comb = 32'h0000006f;   // jal x0, 0
            default: instr_comb = bootrom_ram[imem_addr[IMEM_ADDR_W+1:2]];
        endcase
    end
    
    assign instr = instr_comb;

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

