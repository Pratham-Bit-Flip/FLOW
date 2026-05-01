// control_unit.v - control signal generator for RV32I
module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [4:0] alu_op,
    output reg        alu_src_imm,
    output reg        use_pc_as_rs1,
    output reg        mem_read,
    output reg        mem_write,
    output reg        reg_write,
    output reg        is_branch,
    output reg        is_jal,
    output reg        is_jalr,
    output reg        illegal,
    output reg  [2:0] imm_sel
);

    // opcodes
    localparam OPC_R      = 7'b0110011;
    localparam OPC_I_ALU  = 7'b0010011;
    localparam OPC_LOAD   = 7'b0000011;
    localparam OPC_STORE  = 7'b0100011;
    localparam OPC_BRANCH = 7'b1100011;
    localparam OPC_JAL    = 7'b1101111;
    localparam OPC_JALR   = 7'b1100111;
    localparam OPC_LUI    = 7'b0110111;
    localparam OPC_AUIPC  = 7'b0010111;

    // ALU opcodes
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
    localparam ALU_COPY_B = 5'd10;

    // imm_sel codes
    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_U = 3'b011;
    localparam IMM_J = 3'b100;

    always @(*) begin
        // defaults
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
            OPC_R: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b0;
                imm_sel     = IMM_I;
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
                    3'b101: alu_op = funct7[5] ? ALU_SRA : ALU_SRL;
                    3'b110: alu_op = ALU_OR;
                    3'b111: alu_op = ALU_AND;
                endcase
            end

            OPC_LOAD: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;
                mem_read    = 1'b1;
                alu_op      = ALU_ADD;
                imm_sel     = IMM_I;
            end

            OPC_STORE: begin
                alu_src_imm = 1'b1;
                mem_write   = 1'b1;
                alu_op      = ALU_ADD;
                imm_sel     = IMM_S;
            end

            OPC_BRANCH: begin
                is_branch   = 1'b1;
                alu_src_imm = 1'b0;
                alu_op      = ALU_SUB;
                imm_sel     = IMM_B;
            end

            OPC_JAL: begin
                is_jal        = 1'b1;
                reg_write     = 1'b1;
                alu_src_imm   = 1'b1;
                use_pc_as_rs1 = 1'b1;
                alu_op        = ALU_ADD;
                imm_sel       = IMM_J;
            end

            OPC_JALR: begin
                is_jalr     = 1'b1;
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;
                alu_op      = ALU_ADD;
                imm_sel     = IMM_I;
            end

            OPC_LUI: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;
                alu_op      = ALU_COPY_B;
                imm_sel     = IMM_U;
            end

            OPC_AUIPC: begin
                reg_write     = 1'b1;
                alu_src_imm   = 1'b1;
                use_pc_as_rs1 = 1'b1;
                alu_op        = ALU_ADD;
                imm_sel       = IMM_U;
            end

            default: begin
                illegal = 1'b1;
            end
        endcase
    end
endmodule
