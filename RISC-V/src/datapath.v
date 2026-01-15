// datapath.v -- Single-cycle RV32I datapath

module datapath (
    input  wire        clk,
    input  wire        rst,

    // Instruction memory interface
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,

    // Data memory interface
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    input  wire [31:0] dmem_rdata,
    output wire        dmem_we,
    output wire        dmem_re
);

    // ---------------- PC ----------------
    wire [31:0] pc_current, pc_next, pc_plus4;
    assign pc_plus4 = pc_current + 32'd4;
    assign imem_addr = pc_current;

    pc u_pc (
    .clk(clk),
    .rst(rst),
    .next_pc(pc_next),
    .pc_current(pc_current)
);


    // ---------------- Decode ----------------
    wire [4:0]  alu_op;
    wire        alu_src_imm;
    wire        mem_read, mem_write, reg_write;
    wire        is_branch, is_jal, is_jalr;
    wire [2:0]  imm_sel;
    wire [2:0]  funct3;
    wire        illegal;
    wire        use_pc_as_rs1;
    decoder u_decode (
        .instr(imem_rdata),
        .alu_op(alu_op),
        .alu_src_imm(alu_src_imm),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .reg_write(reg_write),
        .is_branch(is_branch),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .imm_sel(imm_sel),
        .illegal(illegal),
        .use_pc_as_rs1(use_pc_as_rs1),
        .funct3_out(funct3)
    );

    // ---------------- ImmGen ----------------
    wire [31:0] imm;
    immgen u_immgen (
        .instr(imem_rdata),
        .imm_sel(imm_sel),
        .imm_out(imm)
    );

    // ---------------- Register File ----------------
    wire [4:0] rs1 = imem_rdata[19:15];
    wire [4:0] rs2 = imem_rdata[24:20];
    wire [4:0] rd  = imem_rdata[11:7];
    wire [31:0] rs1_data, rs2_data, wb_data;

    reg_file u_regfile (
        .clk(clk),
        .wr_en(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wr_data(wb_data),
        .rd_data1(rs1_data),
        .rd_data2(rs2_data)
    );

    // ---------------- ALU ----------------
    wire [31:0] alu_in_b = alu_src_imm ? imm : rs2_data;
    wire [31:0] alu_result;
    wire        alu_zero;
    wire [31:0] alu_in_a = use_pc_as_rs1 ? pc_current : rs1_data;
    alu u_alu (
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_op(alu_op),
        .y(alu_result),
        .zero(alu_zero)
    );

    // ---------------- Branch Comparator ----------------
    wire take_branch;
    branch_comp u_branchcomp (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .funct3(funct3),
        .take_branch(take_branch)
    );

    // ---------------- Data Memory ----------------
    assign dmem_addr   = alu_result;
    assign dmem_wdata  = rs2_data;
    assign dmem_we     = mem_write;
    assign dmem_re     = mem_read;

    // ---------------- WB mux ----------------
    wb_mux u_wb (
        .alu_result(alu_result),
        .mem_data(dmem_rdata),
        .pc_plus4(pc_plus4),
        .imm_u(imm),   // for LUI/AUIPC
        .sel( (mem_read) ? 2'b01 :
              (is_jal|is_jalr) ? 2'b10 :
              (imm_sel == 3'd3) ? 2'b11 : 2'b00 ),
        .wb_data(wb_data)
    );

    // ---------------- Next PC logic ----------------
    assign pc_next = (is_branch && take_branch) ? (pc_current + imm) :
                     (is_jal)                   ? (pc_current + imm) :
                     (is_jalr)                  ? (alu_result & ~32'd1) :
                                                   pc_plus4;

endmodule
