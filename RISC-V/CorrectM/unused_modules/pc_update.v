// pc_update.v - next PC calculation
module pc_update (
    input  wire [31:0] pc_current,
    input  wire [31:0] imm_out,
    input  wire [31:0] rs1_data,
    input  wire        is_branch,
    input  wire        take_branch,
    input  wire        is_jal,
    input  wire        is_jalr,
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
