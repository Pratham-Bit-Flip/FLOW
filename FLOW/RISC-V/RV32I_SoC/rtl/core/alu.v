// alu.v - 32-bit ALU supporting RV32I base instruction set
module alu
  #(parameter integer WIDTH  =32)
  (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire [4:0]       alu_op,
    output reg  [WIDTH-1:0] y,
    output wire             zero
  );

  // Operation codes
  localparam ALU_ADD    = 5'd0;
  localparam ALU_SUB    = 5'd1;
  localparam ALU_AND    = 5'd2;
  localparam ALU_OR     = 5'd3;
  localparam ALU_XOR    = 5'd4;
  localparam ALU_SLL    = 5'd5;  // left shift
  localparam ALU_SRL    = 5'd6;  // logical right shift
  localparam ALU_SRA    = 5'd7;  // arithmetic right shift
  localparam ALU_SLT    = 5'd8;  // signed less than
  localparam ALU_SLTU   = 5'd9;  // unsigned less than
  localparam ALU_COPY_B = 5'd10;

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

