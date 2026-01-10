// branch_comp.v -- decides whether branch is taken based on funct3
module branch_comp (
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,
    input  wire [2:0]  funct3,
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

