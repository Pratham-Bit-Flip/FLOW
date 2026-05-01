// LED Top Module Testbench
// Tests the complete LED wrapper with heartbeat, bootloader, and CPU

module rv32i_led_top_tb;
    
    // Testbench parameters
    parameter CLOCK_PERIOD = 10;  // 10ns = 100MHz
    parameter SIM_TIME = 100_000_000;  // 1ms simulation
    
    // Signals
    reg sys_clk;
    reg sys_rst_n;
    reg uart_rx;
    wire uart_tx;
    wire [7:0] led;
    
    // Instantiate DUT (Device Under Test)
    rv32i_led_top dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .led(led)
    );
    
    // Clock generation
    always begin
        sys_clk = 1'b0;
        #(CLOCK_PERIOD/2);
        sys_clk = 1'b1;
        #(CLOCK_PERIOD/2);
    end
    
    // Dump waveform
    initial begin
        $dumpfile("rv32i_led_top_tb.vcd");
        $dumpvars(0, rv32i_led_top_tb);
    end
    
    // Test stimulus
    initial begin
        $display("=====================================");
        $display("LED TOP MODULE TESTBENCH");
        $display("=====================================");
        
        // Initialize signals
        sys_rst_n = 1'b0;
        uart_rx = 1'b1;  // UART idle (high)
        
        // Release reset after 100ns
        #100;
        sys_rst_n = 1'b1;
        $display("Reset released at time 100ns");
        
        // Wait for heartbeat to become visible
        #10_000_000;  // Wait 10µs
        $display("Time: 10µs - Heartbeat should be blinking");
        $display("LED[7] (heartbeat):     %b", led[7]);
        $display("LED[4] (boot_done):     %b", led[4]);
        $display("LED[5] (boot_rx_seen):  %b", led[5]);
        
        // Simulate UART activity by toggling RX line
        // Send a byte (start bit)
        #1_000_000;  // After 10µs + 1µs = 11µs
        uart_rx = 1'b0;  // Start bit (low)
        #(8 * 434);  // Hold for ~8 bit periods at 115200 baud
        uart_rx = 1'b1;  // Return to idle
        $display("Time: 11µs - UART byte simulated");
        $display("LED[6] (rx_activity):   %b", led[6]);
        $display("LED[5] (boot_rx_seen):  %b", led[5]);
        
        // Wait for boot timeout (100M cycles = 1 second at 100MHz)
        // Simulation time scaling: let's wait 50M cycles (500µs simulation)
        #50_000_000;
        $display("Time: 61µs - After bootloader timeout");
        $display("LED[4] (boot_done):     %b (should be 1)", led[4]);
        
        // Let simulation run to see heartbeat pattern
        #10_000_000;
        $display("Time: 71µs - Observing heartbeat pattern");
        
        // Final summary
        $display("=====================================");
        $display("FINAL STATE:");
        $display("  LED[7] (heartbeat):    %b", led[7]);
        $display("  LED[6] (rx_activity):  %b", led[6]);
        $display("  LED[5] (boot_rx_seen): %b", led[5]);
        $display("  LED[4] (boot_done):    %b", led[4]);
        $display("  LED[3:0] (firmware):   %b", led[3:0]);
        $display("=====================================");
        
        #SIM_TIME;
        $finish;
    end
    
    // Monitor block to display state changes
    always @(posedge sys_clk) begin
        if ($time % 1_000_000 == 0 && $time > 0) begin
            $display("[%0t ns] LED = %b (H:%b RX:%b SEEN:%b DONE:%b APP:%b)", 
                     $time, led, led[7], led[6], led[5], led[4], led[3:0]);
        end
    end
    
endmodule
