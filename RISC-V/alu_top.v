module alu_top (
  input  wire [31:0] instr,      // current instruction
  input  wire [31:0] pc,         // current PC
  input  wire [31:0] rs1_data,   // register file read port 1
  input  wire [31:0] rs2_data,   // register file read port 2
  input  wire [31:0] mem_rdata,  // data from memory (for loads)

  // ALU outputs
  output wire [31:0] alu_result, 
  output wire        zero,       

  // control signals
  output wire        mem_read,
  output wire        mem_write,
  output wire        reg_write,
  output wire        branch,
  output wire        jump,
  output wire        illegal,
  output wire [2:0]  funct3_out,

  // enhanced outputs
  output wire [31:0] imm_selected, // chosen immediate
  output wire        take_branch,  // branch decision
  output wire [31:0] wb_data       // value to write into rd
);

  // ---------------- Decode ----------------
  wire [4:0] alu_op;
  wire alu_src_imm;
  wire use_pc_as_rs1;

  decode u_decode (
    .instr(instr),
    .alu_op(alu_op),
    .alu_src_imm(alu_src_imm),
    .use_pc_as_rs1(use_pc_as_rs1),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .reg_write(reg_write),
    .branch(branch),
    .jump(jump),
    .illegal(illegal),
    .funct3_out(funct3_out)
  );

  // ---------------- Immediate Generator ----------------
  wire [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

  immgen u_immgen (
    .instr(instr),
    .imm_i(imm_i),
    .imm_s(imm_s),
    .imm_b(imm_b),
    .imm_u(imm_u),
    .imm_j(imm_j)
  );

  // ---------------- Operand Selection ----------------
  reg [31:0] op_a;
  reg [31:0] op_b;
  reg [31:0] imm_sel_r;

  wire [6:0] opcode = instr[6:0];

  always @(*) begin
    // Operand A
    op_a = (use_pc_as_rs1) ? pc : rs1_data;

    // Operand B + selected immediate
    imm_sel_r = 32'b0;
    if (alu_src_imm) begin
      case (opcode)
        7'b0010011, // I-type ALU
        7'b0000011, // LOAD
        7'b1100111: // JALR
          imm_sel_r = imm_i;

        7'b0100011: // STORE
          imm_sel_r = imm_s;

        7'b1100011: // BRANCH
          imm_sel_r = imm_b;

        7'b0110111: // LUI
          imm_sel_r = imm_u;

        7'b0010111, // AUIPC
        7'b1101111: // JAL
          imm_sel_r = imm_j;

        default: 
          imm_sel_r = imm_i;
      endcase
      op_b = imm_sel_r;
    end else begin
      op_b = rs2_data;
    end
  end

  assign imm_selected = imm_sel_r;

  // ---------------- ALU ----------------
  ALU u_alu (
    .a(op_a),
    .b(op_b),
    .alu_op(alu_op),
    .y(alu_result),
    .zero(zero)
  );

  // ---------------- Branch Comparator ----------------
  branch_comp u_branch_comp (
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .funct3(funct3_out),
    .take_branch(take_branch)
  );

  // ---------------- Writeback Data Mux ----------------
  // wb_data = what goes into rd
  assign wb_data =
    (mem_read)  ? mem_rdata :         // load → from memory
    (jump)      ? pc + 32'd4 :        // JAL/JALR → PC+4
    (opcode == 7'b0110111) ? imm_u :  // LUI → imm_u
                             alu_result; // default → ALU result

endmodule

