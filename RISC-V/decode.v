// decode.v - instruction decode (RISC-V RV32I)
module decode (
    input  wire [31:0] instr,        // full 32-bit instruction
    output reg  [4:0]  alu_op,         // ALU operation selector
    output reg         alu_src_imm,    // 1: ALU uses immediate as operand B
    output reg         use_pc_as_rs1,  // 1: use PC instead of rs1
    output reg         mem_read,       // data memory read enable
    output reg         mem_write,      // data memory write enable
    output reg         reg_write,      // register file write enable
    output reg         is_branch,      // branch instruction
    output reg         is_jal,         // JAL instruction
    output reg         is_jalr,        // JALR instruction
    output reg         illegal,        // illegal/unsupported opcode
    output wire [2:0]  funct3_out,     // pass funct3 to later stages
    output reg  [2:0]  imm_sel         // immediate type select for immgen
);

    // extract instruction fields
    wire [6:0] opcode = instr[6:0];     // opcode field
    wire [2:0] funct3 = instr[14:12];   // funct3 field
    wire [6:0] funct7 = instr[31:25];   // funct7 field

    assign funct3_out = funct3;

    // RISC-V base opcodes
    localparam OPC_R      = 7'b0110011;
    localparam OPC_I_ALU  = 7'b0010011;
    localparam OPC_LOAD   = 7'b0000011;
    localparam OPC_STORE  = 7'b0100011;
    localparam OPC_BRANCH = 7'b1100011;
    localparam OPC_JAL    = 7'b1101111;
    localparam OPC_JALR   = 7'b1100111;
    localparam OPC_LUI    = 7'b0110111;
    localparam OPC_AUIPC  = 7'b0010111;

    // internal ALU operation encoding
    localparam ALU_ADD    = 5'd0;
    localparam ALU_SUB    = 5'd1;
    localparam ALU_AND    = 5'd2;
    localparam ALU_OR     = 5'd3;
    localparam ALU_XOR    = 5'd4;
    localparam ALU_SLL    = 5'd5;
    localparam ALU_SRL    = 5'd6;
    localparam ALU_SRA    = 5'd7;
    localparam ALU_SLT    = 5'd8;
    localparam ALU_SLTU   = 5'd9;
    localparam ALU_COPY_B = 5'd10;       // pass immediate directly

    // immediate generator select codes
    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_U = 3'b011;
    localparam IMM_J = 3'b100;

    // combinational decode logic
    always @(*) begin
        // safe defaults (NOP-like)
        alu_op        = ALU_ADD;
        alu_src_imm   = 1'b0;
        use_pc_as_rs1 = 1'b0;
        mem_read      = 1'b0;
        mem_write     = 1'b0;
        reg_write     = 1'b0;
        is_branch     = 1'b0;
        is_jal        = 1'b0;
        is_jalr       = 1'b0;
        illegal       = 1'b0;
        imm_sel       = IMM_I;

        case (opcode)
            // R-type register-register ALU ops
            OPC_R: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b0;
                imm_sel     = IMM_I; // unused but kept consistent
                case (funct3)
                    3'b000: alu_op = funct7[5] ? ALU_SUB : ALU_ADD;
                    3'b001: alu_op = ALU_SLL;
                    3'b010: alu_op = ALU_SLT;
                    3'b011: alu_op = ALU_SLTU;
                    3'b100: alu_op = ALU_XOR;
                    3'b101: alu_op = funct7[5] ? ALU_SRA : ALU_SRL;
                    3'b110: alu_op = ALU_OR;
                    3'b111: alu_op = ALU_AND;
                endcase
            end

            // I-type immediate ALU ops
            OPC_I_ALU: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;
                imm_sel     = IMM_I;
                case (funct3)
                    3'b000: alu_op = ALU_ADD;
                    3'b001: alu_op = ALU_SLL;
                    3'b010: alu_op = ALU_SLT;
                    3'b011: alu_op = ALU_SLTU;
                    3'b100: alu_op = ALU_XOR;
                    3'b101: alu_op = instr[30] ? ALU_SRA : ALU_SRL;
                    3'b110: alu_op = ALU_OR;
                    3'b111: alu_op = ALU_AND;
                endcase
            end

            // load instructions
            OPC_LOAD: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;   // base + offset
                mem_read    = 1'b1;
                alu_op      = ALU_ADD;
                imm_sel     = IMM_I;
            end

            // store instructions
            OPC_STORE: begin
                alu_src_imm = 1'b1;   // base + offset
                mem_write   = 1'b1;
                alu_op      = ALU_ADD;
                imm_sel     = IMM_S;
            end

            // conditional branches
            OPC_BRANCH: begin
                is_branch   = 1'b1;
                alu_src_imm = 1'b0;
                alu_op      = ALU_SUB; // comparison done via subtraction
                imm_sel     = IMM_B;
            end

            // jump and link
            OPC_JAL: begin
                is_jal        = 1'b1;
                reg_write     = 1'b1; // write link register
                alu_src_imm   = 1'b1;
                use_pc_as_rs1 = 1'b1;
                alu_op        = ALU_ADD; // PC + offset
                imm_sel       = IMM_J;
            end

            // jump and link register
            OPC_JALR: begin
                is_jalr     = 1'b1;
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;
                alu_op      = ALU_ADD; // rs1 + offset
                imm_sel     = IMM_I;
            end

            // load upper immediate
            OPC_LUI: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;
                alu_op      = ALU_COPY_B; // immediate << 12 handled in immgen
                imm_sel     = IMM_U;
            end

            // add upper immediate to PC
            OPC_AUIPC: begin
                reg_write     = 1'b1;
                alu_src_imm   = 1'b1;
                use_pc_as_rs1 = 1'b1;
                alu_op        = ALU_ADD;
                imm_sel       = IMM_U;
            end

            // unsupported opcode
            default: begin
                illegal = 1'b1;
            end
        endcase
    end
endmodule
