`timescale 1ns/100ps

module wb_mux_tb;
    reg [31:0] alu_result;
    reg [31:0] mem_data;
    reg [31:0] pc_plus4;
    reg [31:0] imm_u;
    reg [1:0]  sel;
    wire [31:0] wb_data;

    // Instantiate the wb_mux
    wb_mux dut (
        .alu_result(alu_result),
        .mem_data(mem_data),
        .pc_plus4(pc_plus4),
        .imm_u(imm_u),
        .sel(sel),
        .wb_data(wb_data)
    );

    initial begin
        // Waveform dump
        $dumpfile("wb_mux_tb.vcd");
        $dumpvars(0, wb_mux_tb);
        
         $monitor("time=%t | alu_result=%h | mem_data=%h | pc_plus4=%h | imm_u=%h | sel=%b |wb_data=%h", 
                 $time, alu_result,mem_data,pc_plus4,imm_u,sel,wb_data);
        // Initialize inputs
        alu_result = 32'hAAAA_AAAA;
        mem_data   = 32'h5555_5555;
        pc_plus4   = 32'h1111_1111;
        imm_u      = 32'hDEAD_BEEF;

        //  (ALU)
        sel = 2'b00;
        #10;
      

        //  (Mem)
        sel = 2'b01;
        #10;
       
        // (PC+4)
        sel = 2'b10;
        #10;
       

        //(Imm_U)
        sel = 2'b11;
        #10;
        
        $finish;
    end
endmodule

