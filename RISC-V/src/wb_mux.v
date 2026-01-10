module wb_mux (
    input  wire [31:0] alu_result,
    input  wire [31:0] mem_data,
    input  wire [31:0] pc_plus4,
    input  wire [31:0] imm_u,
    input  wire [1:0]  sel,       // 00=ALU, 01=Mem, 10=PC+4, 11=Imm_U
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

