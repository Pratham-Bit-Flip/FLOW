/*============================================================================
 * RV32I CPU TESTBENCH (NON-SELF-CHECKING)
 * 
 * Purpose: Stimulus-based testbench to observe CPU behavior
 * Clock:   100 MHz (10 ns period)
 * Duration: 5000 ns (~500 cycles)
 * 
 * Outputs test signals to VCD file for waveform analysis
 *==========================================================================*/

`timescale 1ns/1ps

module riscv_top_tb;

    localparam integer UART_BAUD = 1_000_000;
    localparam integer BIT_TIME_NS = 1_000_000_000 / UART_BAUD;

    //=========================================================================
    // TESTBENCH SIGNALS
    //=========================================================================
    reg  clk;
    reg  reset;
    
    // CPU outputs
    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] alu_result_out;
    wire [31:0] reg_rs1_out;
    wire [31:0] reg_rs2_out;
    wire [31:0] wb_data_out;
    wire [7:0]  led_out;
    wire        uart_tx;
    wire        uart_rx;
    wire        boot_done = DUT.boot_done;
    reg         tx_start;
    reg  [7:0]  tx_data;
    wire        tx_busy;

    //=========================================================================
    // INSTANTIATE DUT (Device Under Test)
    //=========================================================================
    riscv_top #(.UART_BAUD(UART_BAUD)) DUT (
        .clk(clk),
        .reset(reset),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .alu_result_out(alu_result_out),
        .reg_rs1_out(reg_rs1_out),
        .reg_rs2_out(reg_rs2_out),
        .wb_data_out(wb_data_out),
        .led_out(led_out)
    );

    //=========================================================================
    // CLOCK GENERATION (100 MHz = 10 ns period)
    //=========================================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;  // Toggle every 5 ns
    end

    //=========================================================================
    // VCD WAVEFORM DUMP
    //=========================================================================
    initial begin
        $dumpfile("riscv_top_tb.vcd");
        $dumpvars(0, riscv_top_tb);
    end

    //=========================================================================
    // TEST STIMULUS
    //=========================================================================
    reg [7:0] boot_image [0:31];
    integer i;

    uart_tx #(.CLK_HZ(100_000_000), .BAUD(UART_BAUD)) TB_UART_TX (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(uart_rx),
        .tx_busy(tx_busy)
    );

    task uart_send_byte;
        input [7:0] b;
        begin
            @(posedge clk);
            tx_data  <= b;
            tx_start <= 1'b1;
            @(posedge clk);
            tx_start <= 1'b0;
            wait (tx_busy == 1'b1);  // Wait for transmission to start
            wait (tx_busy == 1'b0);  // Wait for transmission to complete
        end
    endtask

    initial begin
        $display("=====================================");
        $display("RV32I CPU TESTBENCH");
        $display("=====================================");
        $display("Time\tPC\t\tInstr\t\tALU_Result\tReg_RS1\t\tReg_RS2\t\tWB_Data\t\tLED");
        $display("-------------------------------------");

        tx_start = 1'b0;
        tx_data  = 8'd0;

        // Boot image (8 words, little-endian bytes)
        boot_image[0]  = 8'h37; boot_image[1]  = 8'h05; boot_image[2]  = 8'h00; boot_image[3]  = 8'h80;
        boot_image[4]  = 8'h93; boot_image[5]  = 8'h00; boot_image[6]  = 8'h10; boot_image[7]  = 8'h00;
        boot_image[8]  = 8'h23; boot_image[9]  = 8'h20; boot_image[10] = 8'h15; boot_image[11] = 8'h00;
        boot_image[12] = 8'h93; boot_image[13] = 8'h00; boot_image[14] = 8'h20; boot_image[15] = 8'h00;
        boot_image[16] = 8'h23; boot_image[17] = 8'h20; boot_image[18] = 8'h15; boot_image[19] = 8'h00;
        boot_image[20] = 8'h93; boot_image[21] = 8'h00; boot_image[22] = 8'h40; boot_image[23] = 8'h00;
        boot_image[24] = 8'h23; boot_image[25] = 8'h20; boot_image[26] = 8'h15; boot_image[27] = 8'h00;
        boot_image[28] = 8'h6f; boot_image[29] = 8'h00; boot_image[30] = 8'h00; boot_image[31] = 8'hfc;

        // =====================================================================
        // TEST 1: RESET AND INITIALIZATION (0-100 ns)
        // =====================================================================
        reset = 1'b1;
        #20;
        reset = 1'b0;
        #10;
        
        $display("%0d\tReset released", $time);
        
        // =====================================================================
        // TEST 2: UART BOOT DOWNLOAD
        // =====================================================================
        #(BIT_TIME_NS * 10);
        // Send length (32 bytes) and entry (0x00000000)
        uart_send_byte(8'd32);
        uart_send_byte(8'd0);
        uart_send_byte(8'd0);
        uart_send_byte(8'd0);

        uart_send_byte(8'd0); // entry address
        uart_send_byte(8'd0);
        uart_send_byte(8'd0);
        uart_send_byte(8'd0);

        for (i = 0; i < 32; i = i + 1) begin
            uart_send_byte(boot_image[i]);
        end

        // =====================================================================
        // TEST 3: CONTINUE EXECUTION BRIEFLY AFTER BOOT COMPLETE
        // =====================================================================
        wait (boot_done == 1'b1);
        repeat(10) begin
            @(posedge clk) begin
            // Print every 5th cycle to reduce output volume
            if ((cycle_count % 5) == 0) begin
                    $display("%0t\t%h\t%h\t%h\t%h\t%h\t%h\t%h",
                        $time,
                        pc_out,
                        instr_out,
                        alu_result_out,
                        reg_rs1_out,
                        reg_rs2_out,
                        wb_data_out,
                        led_out
                    );
                end
            end
        end

        // =====================================================================
        // TEST 4: FINAL STATE DUMP
        // =====================================================================
        $display("=====================================");
        $display("SIMULATION COMPLETE");
        $display("=====================================");
        $display("Final PC: %h", pc_out);
        $display("Final Instruction: %h", instr_out);
        $display("Final ALU Result: %h", alu_result_out);
        $display("Final Write-Back Data: %h", wb_data_out);
        $display("LED Output: %h", led_out);
        $display("Boot Done: %b", boot_done);
        $display("=====================================");

        $finish;
    end

    //=========================================================================
    // OPTIONAL: MONITOR FOR ILLEGAL INSTRUCTIONS
    //=========================================================================
    always @(posedge clk) begin
        // Check for NOP instruction (all bits 0)
        if (instr_out == 32'h00000000) begin
            // NOP - expected, no action needed
        end
        
        // Check for very large PC values (potential infinite loop)
        if (!boot_done && pc_out > 32'h00001000) begin
            $display("WARNING: PC exceeded 0x00001000 at time %0t: %h", $time, pc_out);
        end
    end

    //=========================================================================
    // OPTIONAL: CYCLE COUNTER
    //=========================================================================
    integer cycle_count;
    initial cycle_count = 0;
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
    end

endmodule
