`timescale 1ns/100ps

module pc_update_tb;
    reg [31:0] pc_current;
    reg [31:0] imm_out;
    reg [31:0] rs1_data;
    reg        is_branch;
    reg        take_branch;
    reg        is_jal;
    reg        is_jalr;
    wire [31:0] pc_next;

    // Instantiate DUT
    pc_update dut (
        .pc_current(pc_current),
        .imm_out(imm_out),
        .rs1_data(rs1_data),
        .is_branch(is_branch),
        .take_branch(take_branch),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .pc_next(pc_next)
    );

    initial begin
        $dumpfile("pc_update_tb.vcd");
        $dumpvars(0, pc_update_tb);
        $monitor("time=%0t | pc_current=%h | rs1_data=%h | imm_out=%h | branch=%b | take=%b | jal=%b | jalr=%b | pc_next=%h",
                 $time, pc_current, rs1_data, imm_out, is_branch, take_branch, is_jal, is_jalr, pc_next);

        // Initial values
        pc_current = 32'h0000_0000; 
        imm_out    = 32'h0000_0000; 
        rs1_data   = 32'h0000_0000;
        is_branch  = 0; take_branch = 0; is_jal = 0; is_jalr = 0;
        #10;

        // Case 1: PC + 4
        pc_current = 32'h0000_0000; 
        #10;

        // Case 2: Branch taken
        is_branch = 1; take_branch = 1; imm_out = 32'h8;
        #10;

        // Case 3: Branch not taken
        take_branch = 0;
        #10;

        // Case 4: JAL
        is_branch = 0; is_jal = 1; imm_out = 32'h12;
        #10;

        // Case 5: JALR
        is_jal = 0; is_jalr = 1; rs1_data = 32'h0000_0010; imm_out = 32'h4;
        #10;

        $finish;
    end
endmodule

