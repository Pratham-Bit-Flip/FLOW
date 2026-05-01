//==========================
// RISC-V TOP MODULE
//==========================
module riscv_top (
    input  wire         clk,
    input  wire         reset,
    
    // Debug / Monitoring outputs
    output wire [31:0]  pc_out,         // current PC value
    output wire [31:0]  instr_out,      // current instruction
    output wire [31:0]  alu_result_out, // ALU result
    output wire [31:0]  reg_rs1_out,    // source register 1 value
    output wire [31:0]  reg_rs2_out,    // source register 2 value
    output wire [31:0]  wb_data_out     // final write-back data
);

    //====================
    // Program Counter
    //====================
    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4;
    
    assign pc_plus4 = pc_current + 32'd4;

    pc PC (
        .clk(clk),
        .rst(reset),
        .next_pc(pc_next),
        .pc_current(pc_current)
    );

    //====================
    // Instruction Memory
    //====================
    wire [31:0] instr;

    instr_mem IMEM (
        .pc(pc_current),
        .instr(instr)
    );

    //====================
    // Decode Stage
    //====================
    wire [4:0] rs1 = instr[19:15];
    wire [4:0] rs2 = instr[24:20];
    wire [4:0] rd  = instr[11:7];

    wire [4:0]  alu_op;
    wire        alu_src_imm;
    wire        use_pc_as_rs1;
    wire        mem_read, mem_write;
    wire        reg_write;
    wire        is_branch, is_jal, is_jalr;
    wire        illegal;
    wire [2:0]  funct3;
    wire [2:0]  imm_sel;

    decoder DEC (
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
        .funct3_out(funct3),
        .imm_sel(imm_sel)
    );

    //====================
    // Immediate Generator
    //====================
    wire [31:0] imm_val;
    
    immgen IMMGEN (
        .instr(instr),
        .imm_sel(imm_sel),
        .imm_out(imm_val)
    );

    //====================
    // Register File
    //====================
    wire [31:0] reg_rs1, reg_rs2, wb_data;

    reg_file RF (
        .clk(clk),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wr_en(reg_write),
        .wr_data(wb_data),
        .rd_data1(reg_rs1),
        .rd_data2(reg_rs2)
    );

    //====================
    // ALU
    //====================
    wire [31:0] alu_in_a = use_pc_as_rs1 ? pc_current : reg_rs1;
    wire [31:0] alu_in_b = alu_src_imm ? imm_val : reg_rs2;
    wire [31:0] alu_result;
    wire        alu_zero;

    alu #(.WIDTH(32)) ALU (
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_op(alu_op),
        .y(alu_result),
        .zero(alu_zero)
    );

    //====================
    // Branch Comparator
    //====================
    wire take_branch;

    branch_comp BCMP (
        .rs1_data(reg_rs1),
        .rs2_data(reg_rs2),
        .funct3(funct3),
        .take_branch(take_branch)
    );

    //====================
    // Data Memory
    //====================
    wire [31:0] data_mem_out;

    data_mem DMEM (
        .clk(clk),
        .memwrite(mem_write),
        .memread(mem_read),
        .funct3(funct3),
        .addr(alu_result),
        .writedata(reg_rs2),
        .readdata(data_mem_out)
    );

    //====================
    // Write-back MUX
    //====================
    wire [1:0] wb_sel;

    assign wb_sel = (mem_read)         ? 2'b01 :
                    (is_jal | is_jalr) ? 2'b10 :
                    (imm_sel == 3'd3)  ? 2'b11 : 2'b00;

    wb_mux WBMUX (
        .alu_result(alu_result),
        .mem_data(data_mem_out),
        .pc_plus4(pc_plus4),
        .imm_u(imm_val),
        .sel(wb_sel),
        .wb_data(wb_data)
    );

    //====================
    // Next PC Logic
    //====================
    assign pc_next = (is_branch && take_branch) ? (pc_current + imm_val) :
                     (is_jal)                   ? (pc_current + imm_val) :
                     (is_jalr)                  ? (alu_result & ~32'd1) :
                                                   pc_plus4;

    //====================
    // Assign top-level outputs
    //====================
    assign pc_out         = pc_current;
    assign instr_out      = instr;
    assign alu_result_out = alu_result;
    assign reg_rs1_out    = reg_rs1;
    assign reg_rs2_out    = reg_rs2;
    assign wb_data_out    = wb_data;

endmodule

