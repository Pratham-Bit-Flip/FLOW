`timescale 1ns / 1ps

module decoder_tb;
    reg [31:0] instr;
    wire [4:0] alu_op;
    wire alu_src_imm;
    wire use_pc_as_rs1;
    wire mem_read;
    wire mem_write;
    wire reg_write;
    wire is_branch;
    wire is_jal;
    wire is_jalr;
    wire illegal;
    wire [2:0] funct3_out;
    wire [2:0] imm_sel;
    
    // Instantiate decoder
    decoder uut (
        .instr(instr),
        .alu_op(alu_op),
        .alu_src_imm(alu_src_imm),
        .use_pc_as_rs1(use_pc_as_rs1),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .reg_write(reg_write),
        .is_branch(is_branch),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .illegal(illegal),
        .funct3_out(funct3_out),
        .imm_sel(imm_sel)
    );
    
    initial begin
        $dumpfile("decoder_tb.vcd");
        $dumpvars(0, decoder_tb);
        
        $display("\n=== DECODER VERIFICATION TEST ===\n");
        
        // TEST 1: ADD (R-type)
        $display("TEST 1: ADD x5, x10, x15 (R-type)");
        instr = 32'h00f502b3; // ADD x5, x10, x15
        #10;
        $display("  alu_op=%d (0=ADD), reg_write=%b, alu_src_imm=%b", alu_op, reg_write, alu_src_imm);
        if (alu_op == 0 && reg_write == 1 && alu_src_imm == 0)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        
        // TEST 2: ADDI (I-type ALU)
        $display("\nTEST 2: ADDI x5, x10, 100 (I-type)");
        instr = 32'h06450293; // ADDI x5, x10, 100
        #10;
        $display("  alu_op=%d (0=ADD), reg_write=%b, alu_src_imm=%b, imm_sel=%b", 
                 alu_op, reg_write, alu_src_imm, imm_sel);
        if (alu_op == 0 && reg_write == 1 && alu_src_imm == 1 && imm_sel == 3'b000)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        
        // TEST 3: LW (Load)
        $display("\nTEST 3: LW x5, 8(x10) (Load)");
        instr = 32'h00852283; // LW x5, 8(x10)
        #10;
        $display("  mem_read=%b, reg_write=%b, alu_src_imm=%b, imm_sel=%b", 
                 mem_read, reg_write, alu_src_imm, imm_sel);
        if (mem_read == 1 && reg_write == 1 && alu_src_imm == 1 && imm_sel == 3'b000)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        
        // TEST 4: SW (Store)
        $display("\nTEST 4: SW x15, 12(x10) (Store)");
        instr = 32'h00f52623; // SW x15, 12(x10)
        #10;
        $display("  mem_write=%b, reg_write=%b, alu_src_imm=%b, imm_sel=%b", 
                 mem_write, reg_write, alu_src_imm, imm_sel);
        if (mem_write == 1 && reg_write == 0 && alu_src_imm == 1 && imm_sel == 3'b001)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        
        // TEST 5: BEQ (Branch)
        $display("\nTEST 5: BEQ x5, x10, 16 (Branch)");
        instr = 32'h00a28863; // BEQ x5, x10, 16
        #10;
        $display("  is_branch=%b, reg_write=%b, imm_sel=%b", 
                 is_branch, reg_write, imm_sel);
        if (is_branch == 1 && reg_write == 0 && imm_sel == 3'b010)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        
        // TEST 6: JAL (Jump and Link)
        $display("\nTEST 6: JAL x1, 2048 (Jump)");
        instr = 32'h000010ef; // JAL x1, 2048
        #10;
        $display("  is_jal=%b, reg_write=%b, use_pc_as_rs1=%b, imm_sel=%b", 
                 is_jal, reg_write, use_pc_as_rs1, imm_sel);
        if (is_jal == 1 && reg_write == 1 && use_pc_as_rs1 == 1 && imm_sel == 3'b100)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        
        // TEST 7: JALR (Jump and Link Register)
        $display("\nTEST 7: JALR x1, 0(x10) (Jump Register)");
        instr = 32'h000500e7; // JALR x1, 0(x10)
        #10;
        $display("  is_jalr=%b, reg_write=%b, alu_src_imm=%b, imm_sel=%b", 
                 is_jalr, reg_write, alu_src_imm, imm_sel);
        if (is_jalr == 1 && reg_write == 1 && alu_src_imm == 1 && imm_sel == 3'b000)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        
        // TEST 8: LUI (Load Upper Immediate)
        $display("\nTEST 8: LUI x10, 0x12345 (Load Upper Imm)");
        instr = 32'h12345537; // LUI x10, 0x12345
        #10;
        $display("  alu_op=%d (10=COPY_B), reg_write=%b, alu_src_imm=%b, imm_sel=%b", 
                 alu_op, reg_write, alu_src_imm, imm_sel);
        if (alu_op == 10 && reg_write == 1 && alu_src_imm == 1 && imm_sel == 3'b011)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        
        // TEST 9: AUIPC (Add Upper Immediate to PC)
        $display("\nTEST 9: AUIPC x10, 0x12345 (Add Upper Imm to PC)");
        instr = 32'h12345517; // AUIPC x10, 0x12345
        #10;
        $display("  alu_op=%d (0=ADD), reg_write=%b, use_pc_as_rs1=%b, imm_sel=%b", 
                 alu_op, reg_write, use_pc_as_rs1, imm_sel);
        if (alu_op == 0 && reg_write == 1 && use_pc_as_rs1 == 1 && imm_sel == 3'b011)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        
        // TEST 10: SUB (R-type with funct7 bit)
        $display("\nTEST 10: SUB x5, x10, x15 (R-type SUB)");
        instr = 32'h40f502b3; // SUB x5, x10, x15
        #10;
        $display("  alu_op=%d (1=SUB), reg_write=%b", alu_op, reg_write);
        if (alu_op == 1 && reg_write == 1)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        
        // TEST 11: XOR (R-type)
        $display("\nTEST 11: XOR x5, x10, x15 (R-type XOR)");
        instr = 32'h00f54233; // XOR x5, x10, x15
        #10;
        $display("  alu_op=%d (4=XOR), funct3=%b", alu_op, funct3_out);
        if (alu_op == 4 && funct3_out == 3'b100)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        
        // TEST 12: Illegal instruction
        $display("\nTEST 12: Illegal instruction (invalid opcode)");
        instr = 32'hFFFFFFFF; // All 1s - opcode = 0x7F (invalid)
        #10;
        $display("  illegal=%b (opcode=0x%02x)", illegal, instr[6:0]);
        if (illegal == 1)
            $display("  ✓ PASS");
        else
            $display("  ✗ FAIL");
        
        $display("\n=== Verification Complete ===\n");
        $finish;
    end
endmodule
