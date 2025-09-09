// Generation of 32-bit immediate
module immgen(
	input wire [31:0] instr,
	output wire [31:0] imm_i,
	output wire [31:0] imm_s,
	output wire [31:0] imm_b,
	output wire [31:0] imm_u,
	output wire [31:0] imm_j
	);
	
	//I-type:imm[11:0]-(12 bits sign extended to 32)
	assign imm_i = {{20{instr[31]}},instr[31:20]};
	
	//S-type:imm[11:5,4:0]-(12 bits)
	assign imm_s = {{20{instr[31]}},instr[31:25],instr[11:7]};
	
	//B-type:imm[12,10:5,4:1,11]-(12 bits, offset->shift left by 1)
	assign imm_b = {{19{instr[31]}},instr[31],instr[7],instr[31:25],instr[11:8],1'b0};
	
	//U-type:imm[31:12]-(20 bits, imm<<12)
	assign imm_u = {instr[31:12],12'b0};
	
	//J-type:imm[20,10:1,11,19:12]-(20 bits, offset->shift left by 1)
	assign imm_j = {{11{instr[31]}},instr[31],instr[19:12],instr[20],instr[30:21],1'b0};
	
endmodule
