// Not Completed

module decoder1(
    input  wire [6:0] opcode,    
    output wire        alu_src,    
    output wire        mem_to_reg, 
    output wire        reg_write,  
    output wire        mem_read,   
    output wire        mem_write,  
    output wire        branch,     
    output wire [1:0]  alu_op     
);

    // RISC-V base opcodes
    localparam OPC_R      = 7'b0110011; 
    localparam OPC_I_LOAD = 7'b0000011; 
    localparam OPC_S      = 7'b0100011;  
    localparam OPC_B      = 7'b1100011; 
    localparam OPC_JAL    = 7'b1101111;  
    localparam OPC_JALR   = 7'b1100111;  
    localparam OPC_I_ALU  = 7'b0010011;  

    // Control Signal Assignments 

    //  Use immediate for I-Type, Load, Store
    assign alu_src = (opcode == OPC_I_ALU)  |
                     (opcode == OPC_I_LOAD) |
                     (opcode == OPC_S);

    //  Use memory result only for Load
    assign mem_to_reg = (opcode == OPC_I_LOAD);

    //  Write back result for R-Type, I-Type, Load, JAL, JALR
    assign reg_write = (opcode == OPC_R)      |
                       (opcode == OPC_I_ALU)  |
                       (opcode == OPC_I_LOAD) |
                       (opcode == OPC_JAL)    |
                       (opcode == OPC_JALR);

    //  Enable memory read only for Load
    assign mem_read = (opcode == OPC_I_LOAD);

    //  Enable memory write only for Store
    assign mem_write = (opcode == OPC_S);

    // Enable branch only for Branch
    assign branch = (opcode == OPC_B);

    //   2-bit operation control
    assign alu_op = (opcode == OPC_R)     ? 2'b10 :    // R-type ALU
                    (opcode == OPC_I_ALU) ? 2'b11 :    // I-type ALU
                    (opcode == OPC_B)     ? 2'b01 :    // Branch (Compare)
                                            2'b00;     // Default/Load/Store (ADD for address)

endmodule
