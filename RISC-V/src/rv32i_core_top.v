module rv32i_core_top (
    input  wire clk,
    input  wire rst
);

    // =========================================================================
    // Instruction Memory (Simple ROM for now)
    // =========================================================================
    reg [31:0] imem [0:255];   // 256 x 32-bit words = 1 KB instruction memory
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;

    assign imem_rdata = imem[imem_addr[9:2]];  // word-addressed

    // =========================================================================
    // Data Memory (Simple RAM)
    // =========================================================================
    reg [31:0] dmem [0:255];   // 256 x 32-bit words = 1 KB data memory
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;
    wire        dmem_we, dmem_re;

    // Read operation
    assign dmem_rdata = (dmem_re) ? dmem[dmem_addr[9:2]] : 32'b0;

    // Write operation
    always @(posedge clk) begin
        if (dmem_we)
            dmem[dmem_addr[9:2]] <= dmem_wdata;
    end

    // =========================================================================
    // Datapath Integration
    // =========================================================================
    datapath u_datapath (
        .clk(clk),
        .rst(rst),

        // Instruction memory connection
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),

        // Data memory connection
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata),
        .dmem_we(dmem_we),
        .dmem_re(dmem_re)
    );

    // =========================================================================
    // Optional: Initialize instruction memory for simulation
    // =========================================================================
    initial begin
        $readmemh("program.hex", imem);  // Load your compiled RISC-V program
        $display("Instruction memory initialized from program.hex");
    end

endmodule
