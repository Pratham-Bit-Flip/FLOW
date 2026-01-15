module instr_mem(
    input  wire [31:0] pc,
    output reg  [31:0] instr
);
    reg [31:0] memory [0:255];
    integer i;  // Declare outside the initial block
    
    initial begin
        memory[0] = 32'h00500093; //Address 0:  ADDI x1, x0, 5     # x1 = 5
        memory[1] = 32'h00A00113; //Address 1:  ADDI x2, x0, 10    # x2 = 10
        memory[2] = 32'h002081B3; //Address 2:  ADD  x3, x1, x2    # x3 = 5 + 10 = 15
        for (i = 3; i < 256; i = i + 1)
            memory[i] = 32'h00000013; //Address 3+: NOP (do nothing)
    end
    
    always @(*) begin
        instr = memory[pc[9:2]];
    end
endmodule
