
module alu
  #(parameter integer WIDTH = 32)
  (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [4:0]       alu_op,
    output reg  [WIDTH-1:0] y,
    output wire             zero
  );

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
  localparam ALU_COPY_B = 5'd10; // renamed for consistency

  // shift amount width
  localparam integer SHAMT_W = (WIDTH <= 2) ? 1 : $clog2(WIDTH);
  wire [SHAMT_W-1:0] shamt = b[SHAMT_W-1:0];

  always @(*) begin
    case (alu_op)
      ALU_ADD:    y = a + b;
      ALU_SUB:    y = a - b;
      ALU_AND:    y = a & b;
      ALU_OR:     y = a | b;
      ALU_XOR:    y = a ^ b;
      ALU_SLL:    y = a << shamt;
      ALU_SRL:    y = a >> shamt;
      ALU_SRA:    y = $signed(a) >>> shamt;   
      ALU_SLT:    y = ($signed(a) < $signed(b)) ? {{WIDTH-1{1'b0}}, 1'b1} : {WIDTH{1'b0}};
      ALU_SLTU:   y = (a < b) ? {{WIDTH-1{1'b0}}, 1'b1} : {WIDTH{1'b0}};
      ALU_COPY_B: y = b;
      default:    y = {WIDTH{1'b0}}; 
    endcase
  end

  assign zero = (y == {WIDTH{1'b0}});

endmodule

// branch_comp.v -- decides whether branch is taken based on funct3
module branch_comp (
    input  [31:0] rs1_data,
    input  [31:0] rs2_data,
    input  [2:0]  funct3,
    output reg         take_branch
);

    always @(*) begin
        case (funct3)
            3'b000: take_branch = (rs1_data == rs2_data);                // BEQ
            3'b001: take_branch = (rs1_data != rs2_data);                // BNE
            3'b100: take_branch = ($signed(rs1_data) <  $signed(rs2_data)); // BLT
            3'b101: take_branch = ($signed(rs1_data) >= $signed(rs2_data)); // BGE
            3'b110: take_branch = (rs1_data < rs2_data);                 // BLTU
            3'b111: take_branch = (rs1_data >= rs2_data);                // BGEU
            default: take_branch = 1'b0;
        endcase
    end

endmodule

module data_mem(
    input         clk,
    input         memwrite,      // write enable
    input         memread,       // read enable
    input  [2:0]  funct3,        // operation type (NEW)
    input  [31:0] addr,          // byte address
    input  [31:0] writedata,     // data to write
    output reg  [31:0] readdata       // data to read
);
    reg [31:0] memory [0:255];

    // Word index and byte offset
    wire [7:0]  word_idx   = addr[9:2];
    wire [1:0]  byte_off   = addr[1:0];
    wire [31:0] mem_word   = memory[word_idx];

    // funct3 encoding:
    // 000 = LB/SB,  001 = LH/SH,  010 = LW/SW
    // 100 = LBU,    101 = LHU

    //================== WRITE (Store) ==================
    always @(posedge clk) begin
        if (memwrite) begin
            case (funct3[1:0])
                2'b00: begin // SB - Store Byte
                    case (byte_off)
                        2'b00: memory[word_idx][7:0]   <= writedata[7:0];
                        2'b01: memory[word_idx][15:8]  <= writedata[7:0];
                        2'b10: memory[word_idx][23:16] <= writedata[7:0];
                        2'b11: memory[word_idx][31:24] <= writedata[7:0];
                    endcase
                end
                2'b01: begin // SH - Store Halfword
                    case (byte_off[1])
                        1'b0: memory[word_idx][15:0]  <= writedata[15:0];
                        1'b1: memory[word_idx][31:16] <= writedata[15:0];
                    endcase
                end
                2'b10: begin // SW - Store Word
                    memory[word_idx] <= writedata;
                end
                default: memory[word_idx] <= writedata;
            endcase
        end
    end

    //================== READ (Load) ==================
    always @(*) begin
        if (memread) begin
            case (funct3)
                3'b000: begin // LB - Load Byte (signed)
                    case (byte_off)
                        2'b00: readdata = {{24{mem_word[7]}},  mem_word[7:0]};
                        2'b01: readdata = {{24{mem_word[15]}}, mem_word[15:8]};
                        2'b10: readdata = {{24{mem_word[23]}}, mem_word[23:16]};
                        2'b11: readdata = {{24{mem_word[31]}}, mem_word[31:24]};
                    endcase
                end
                3'b001: begin // LH - Load Halfword (signed)
                    case (byte_off[1])
                        1'b0: readdata = {{16{mem_word[15]}}, mem_word[15:0]};
                        1'b1: readdata = {{16{mem_word[31]}}, mem_word[31:16]};
                    endcase
                end
                3'b010: begin // LW - Load Word
                    readdata = mem_word;
                end
                3'b100: begin // LBU - Load Byte Unsigned
                    case (byte_off)
                        2'b00: readdata = {24'b0, mem_word[7:0]};
                        2'b01: readdata = {24'b0, mem_word[15:8]};
                        2'b10: readdata = {24'b0, mem_word[23:16]};
                        2'b11: readdata = {24'b0, mem_word[31:24]};
                    endcase
                end
                3'b101: begin // LHU - Load Halfword Unsigned
                    case (byte_off[1])
                        1'b0: readdata = {16'b0, mem_word[15:0]};
                        1'b1: readdata = {16'b0, mem_word[31:16]};
                    endcase
                end
                default: readdata = mem_word;
            endcase
        end else begin
            readdata = 32'b0;
        end
    end
endmodule
// datapath.v -- Single-cycle RV32I datapath

module datapath (
    input         clk,
    input         rst,

    // Instruction memory interface
    output wire [31:0] imem_addr,
    input  [31:0] imem_rdata,

    // Data memory interface
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    input  [31:0] dmem_rdata,
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

// decode.v - instruction decode
module decoder (
    input  [31:0] instr,
    output reg  [4:0]  alu_op,
    output reg         alu_src_imm,
    output reg         use_pc_as_rs1,
    output reg         mem_read,
    output reg         mem_write,
    output reg         reg_write,
    output reg         is_branch,
    output reg         is_jal,
    output reg         is_jalr,
    output reg         illegal,
    output wire [2:0]  funct3_out,
    output reg  [2:0]  imm_sel     // NEW: drives immgen
);

    // extract fields
    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

    assign funct3_out = funct3;

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
                    3'b101: alu_op = instr[30] ? ALU_SRA : ALU_SRL;
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


module immgen (
    input  [31:0] instr,    
    input  [2:0]  imm_sel,   
    output reg  [31:0] imm_out    // Sign-extended immediate
);

    always @(*) begin
        case (imm_sel)

            // I-type 
            3'b000: imm_out = { {20{instr[31]}}, instr[31:20] };

            // S-type
            3'b001: imm_out = { {20{instr[31]}}, instr[31:25], instr[11:7] };

            // B-type 
            3'b010: imm_out = { {19{instr[31]}}, instr[31], instr[7],
                                instr[30:25], instr[11:8], 1'b0 };

            // U-type
            3'b011: imm_out = { instr[31:12], 12'b0 };

            // J-type 
            3'b100: imm_out = { {11{instr[31]}}, instr[31], instr[19:12],
                                instr[20], instr[30:21], 1'b0 };

            // Default
            default: imm_out = 32'b0;

        endcase
    end

endmodule


module instr_mem(
    input  [31:0] pc,
    output reg  [31:0] instr
);
    // Small instruction memory (32 words) with LED pattern program
    reg [31:0] memory [0:31];
    integer i;

    initial begin
        // x10 = 0x8000_0000 (LED MMIO)
        memory[0]  = 32'h80000537; // LUI x10, 0x80000
        
        // x11 = delay counter (countdown)
        memory[1]  = 32'h01c00593; // ADDI x11, x0, 28 (delay loop count)
        
        // LED pattern sequence with delays
        // LED 0x01
        memory[2]  = 32'h00100093; // ADDI x1, x0, 1
        memory[3]  = 32'h00152023; // SW x1, 0(x10)
        memory[4]  = 32'h01c00593; // ADDI x11, x0, 28 (reload delay)
        // Delay loop: BNE x11, x0, -4
        memory[5]  = 32'hffc5a663; // BNE x11, x0, -10 (branch to delay start)
        
        // LED 0x02
        memory[6]  = 32'h00200093; // ADDI x1, x0, 2
        memory[7]  = 32'h00152023; // SW x1, 0(x10)
        memory[8]  = 32'h01c00593; // ADDI x11, x0, 28
        memory[9]  = 32'hffc5a663; // BNE x11, x0, -10
        
        // LED 0x04
        memory[10] = 32'h00400093; // ADDI x1, x0, 4
        memory[11] = 32'h00152023; // SW x1, 0(x10)
        memory[12] = 32'h01c00593; // ADDI x11, x0, 28
        memory[13] = 32'hffc5a663; // BNE x11, x0, -10
        
        // LED 0x08
        memory[14] = 32'h00800093; // ADDI x1, x0, 8
        memory[15] = 32'h00152023; // SW x1, 0(x10)
        
        // Jump back to start (loop)
        memory[16] = 32'hfc00006f; // JAL x0, -64 (jump back to memory[1])
        
        // Fill rest with NOPs
        for (i = 17; i < 32; i = i + 1)
            memory[i] = 32'h00000013; // NOP
    end

    always @(*) begin
        instr = memory[pc[6:2]]; // wrap naturally every 32 words
    end
endmodule


// pc_update.v - next PC calculation
module pc_update (
    input  [31:0] pc_current,
    input  [31:0] imm_out,
    input  [31:0] rs1_data,
    input         is_branch,
    input         take_branch,
    input         is_jal,
    input         is_jalr,
    output reg  [31:0] pc_next
);

    always @(*) begin
        if (is_branch && take_branch)
            pc_next = pc_current + imm_out;
        else if (is_jal)
            pc_next = pc_current + imm_out;
        else if (is_jalr)
            pc_next = (rs1_data + imm_out) & ~32'b1; // align
        else
            pc_next = pc_current + 32'd4;
    end

endmodule


// pc_update.v - next PC calculation
module pc_update (
    input  [31:0] pc_current,
    input  [31:0] imm_out,
    input  [31:0] rs1_data,
    input         is_branch,
    input         take_branch,
    input         is_jal,
    input         is_jalr,
    output reg  [31:0] pc_next
);

    always @(*) begin
        if (is_branch && take_branch)
            pc_next = pc_current + imm_out;
        else if (is_jal)
            pc_next = pc_current + imm_out;
        else if (is_jalr)
            pc_next = (rs1_data + imm_out) & ~32'b1; // align
        else
            pc_next = pc_current + 32'd4;
    end

endmodule


 module pc (
    input       clk,
    input       rst,
	input [31:0] next_pc, // Next Cycle
    output reg [31:0] pc_current
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_current <= 32'h0000_0000;   // reset to 0
        else
            pc_current <= next_pc;     // next cycle
    end

endmodule




module reg_file(
    input   clk,
    input   wr_en,           // write enable
    input  [4:0]  rs1, rs2, rd,  //source regs and destination reg
    input  [31:0] wr_data,           // write data
    output wire [31:0] rd_data1, rd_data2      // read data outputs
);
    reg [31:0] regs[0:31];           // 32 registers

    // Read (combinational)
    assign rd_data1 = (rs1 == 0) ? 32'b0 : regs[rs1];
    assign rd_data2 = (rs2 == 0) ? 32'b0 : regs[rs2];

    // Write (synchronous)
    always @(posedge clk) begin
        if (wr_en && rd != 0)
            regs[rd] <= wr_data;
    end
endmodule



//==========================
// RISC-V TOP MODULE
//==========================
module riscv_top (
    input          clk,
    input          reset,
    
    // Debug / Monitoring outputs
    output wire [31:0]  pc_out,         // current PC value
    output wire [31:0]  instr_out,      // current instruction
    output wire [31:0]  alu_result_out, // ALU result
    output wire [31:0]  reg_rs1_out,    // source register 1 value
    output wire [31:0]  reg_rs2_out,    // source register 2 value
    output wire [31:0]  wb_data_out,    // final write-back data
    output wire [7:0]   led_out         // memory-mapped LED register
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
        .reset(reset),
        .memwrite(mem_write),
        .memread(mem_read),
        .funct3(funct3),
        .addr(alu_result),
        .writedata(reg_rs2),
        .readdata(data_mem_out),
        .led_out(led_out)
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



module wb_mux (
    input  [31:0] alu_result,
    input  [31:0] mem_data,
    input  [31:0] pc_plus4,
    input  [31:0] imm_u,
    input  [1:0]  sel,       // 00=ALU, 01=Mem, 10=PC+4, 11=Imm_U
    output reg  [31:0] wb_data
);
    always @(*) begin
        case (sel)
            2'b00: wb_data = alu_result;
            2'b01: wb_data = mem_data;
            2'b10: wb_data = pc_plus4;
            2'b11: wb_data = imm_u;
            default: wb_data = 32'b0;
        endcase
    end
endmodule



// Generic RV32I SoC wrapper
// Instantiates full RV32I core with MMIO LED output

module rv32i_led_top (
    input        sys_clk,
    input        sys_rst_n,
    output wire [7:0] led
);
    // Active-high reset for riscv_top
    wire reset = ~sys_rst_n;

    // Wires from CPU
    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] alu_result_out;
    wire [31:0] reg_rs1_out;
    wire [31:0] reg_rs2_out;
    wire [31:0] wb_data_out;
    wire [7:0]  led_mmio;

    riscv_top cpu (
        .clk(sys_clk),
        .reset(reset),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .alu_result_out(alu_result_out),
        .reg_rs1_out(reg_rs1_out),
        .reg_rs2_out(reg_rs2_out),
        .wb_data_out(wb_data_out),
        .led_out(led_mmio)
    );

    // Drive LEDs via CPU MMIO register
    assign led = led_mmio;
endmodule
