`timescale 1ns / 1ps

module wb_mux_tb;
    reg [31:0] alu_result;
    reg [31:0] mem_data;
    reg [31:0] pc_plus4;
    reg [31:0] imm_u;
    reg [1:0] sel;
    wire [31:0] wb_data;
    
    // Instantiate writeback mux
    wb_mux uut (
        .alu_result(alu_result),
        .mem_data(mem_data),
        .pc_plus4(pc_plus4),
        .imm_u(imm_u),
        .sel(sel),
        .wb_data(wb_data)
    );
    
    initial begin
        $dumpfile("wb_mux_tb.vcd");
        $dumpvars(0, wb_mux_tb);
        
        $display("\n=== WRITEBACK MUX VERIFICATION TEST ===\n");
        
        // Setup test values
        alu_result = 32'h12345678;
        mem_data = 32'hDEADBEEF;
        pc_plus4 = 32'h00001004;
        imm_u = 32'hABCD0000;
        
        // TEST 1: Select ALU result
        $display("TEST 1: Select ALU result (sel=00)");
        sel = 2'b00; #10;
        $display("  wb_data: 0x%08x (expected 0x12345678)", wb_data);
        if (wb_data == 32'h12345678) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 2: Select memory data
        $display("\nTEST 2: Select memory data (sel=01)");
        sel = 2'b01; #10;
        $display("  wb_data: 0x%08x (expected 0xDEADBEEF)", wb_data);
        if (wb_data == 32'hDEADBEEF) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 3: Select PC+4
        $display("\nTEST 3: Select PC+4 (sel=10)");
        sel = 2'b10; #10;
        $display("  wb_data: 0x%08x (expected 0x00001004)", wb_data);
        if (wb_data == 32'h00001004) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 4: Select immediate U
        $display("\nTEST 4: Select immediate U (sel=11)");
        sel = 2'b11; #10;
        $display("  wb_data: 0x%08x (expected 0xABCD0000)", wb_data);
        if (wb_data == 32'hABCD0000) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        // TEST 5: Change inputs and verify mux still works
        $display("\nTEST 5: Dynamic input changes");
        alu_result = 32'hCAFEBABE;
        sel = 2'b00; #10;
        $display("  ALU select: 0x%08x (expected 0xCAFEBABE)", wb_data);
        if (wb_data == 32'hCAFEBABE) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        mem_data = 32'h00FACADE;
        sel = 2'b01; #10;
        $display("  MEM select: 0x%08x (expected 0x00FACADE)", wb_data);
        if (wb_data == 32'h00FACADE) $display("  ✓ PASS"); else $display("  ✗ FAIL");
        
        $display("\n=== Verification Complete ===\n");
        $finish;
    end
endmodule
