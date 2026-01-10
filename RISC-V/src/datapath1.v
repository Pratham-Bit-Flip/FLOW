
module datapath1 (
    input  wire        clk,
    input  wire        rst,

    // Control signals from decode
    input  wire [4:0]  alu_op,
    input  wire        alu_src_imm,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire        reg_write,
    input  wire        is_branch,
    input  wire        is_jal,
    input  wire        is_jalr,
    input  wire [2:0]  imm_sel,

    // From decode to datapath (funct3 for branch)
    input  wire [2:0]  funct3,

    // Instruction from instruction memory
    input  wire [31:0] instr,

    // Data memory interface
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    input  wire [31:0] dmem_rdata,
    output wire        dmem_we,
    output wire        dmem_re,

    // Next instruction address
    output wire [31:0] imem_addr
);


    // PC Logic

    wire [31:0] pc_current, pc_next, pc_plus4;
    assign pc_plus4 = pc_current + 32'd4;
    assign imem_addr = pc_current;

    pc u_pc (
        .clk(clk),
        .rst(rst),
        .next_pc(pc_next),
        .pc_current(pc_current)
    );

    
    // Immediate Generator

    wire [31:0] imm_out;
    immgen u_imm (
        .instr(instr),
        .imm_sel(imm_sel),
        .imm_out(imm_out)
    );


    // Register File

    wire [4:0] rs1 = instr[19:15];
    wire [4:0] rs2 = instr[24:20];
    wire [4:0] rd  = instr[11:7];

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


    // ALU Input Selection

    wire [31:0] alu_in_b = alu_src_imm ? imm_out : rs2_data;
    wire [31:0] alu_result;
    wire        alu_zero;

    alu u_alu (
        .a(rs1_data),
        .b(alu_in_b),
        .alu_op(alu_op),
        .y(alu_result),
        .zero(alu_zero)
    );


    // Branch Comparator

    wire take_branch;
    branch_comp u_branchcomp (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .funct3(funct3),
        .take_branch(take_branch)
    );


    // Data Memory Interface

    assign dmem_addr  = alu_result;
    assign dmem_wdata = rs2_data;
    assign dmem_we    = mem_write;
    assign dmem_re    = mem_read;


    // Writeback MUX

    wb_mux u_wb (
        .alu_result(alu_result),
        .mem_data(dmem_rdata),
        .pc_plus4(pc_plus4),
        .imm_u(imm_out),
        .sel((mem_read) ? 2'b01 :
             (is_jal | is_jalr) ? 2'b10 :
             (imm_sel == 3'd3) ? 2'b11 : 2'b00),
        .wb_data(wb_data)
    );


    // Next PC Logic

    pc_update u_pcupdate (
        .pc_current(pc_current),
        .imm_out(imm_out),
        .rs1_data(rs1_data),
        .is_branch(is_branch),
        .take_branch(take_branch),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .pc_next(pc_next)
    );

endmodule
