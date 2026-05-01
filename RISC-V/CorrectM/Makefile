# Makefile for RISC-V RV32I Testbenches

# Compiler settings
VERILOG = iverilog
VVP = vvp
VFLAGS = -g2009

# Source directory
SRC_DIR = .
TB_DIR = tb
BUILD_DIR = sim_build

# List of testbenches and their corresponding modules
TESTBENCHES = \
	alu_tb \
	branch_comp_tb \
	decoder_tb \
	immgen_tb \
	instr_mem_tb \
	pc_tb \
	pc_update_tb \
	reg_file_tb \
	data_mem_tb \
	wb_mux_tb \
	datapath_tb

# Module dependencies
ALU_DEPS = alu.v $(TB_DIR)/alu_tb.v
BRANCH_COMP_DEPS = branch_comp.v $(TB_DIR)/branch_comp_tb.v
DECODER_DEPS = decoder.v $(TB_DIR)/decoder_tb.v
IMMGEN_DEPS = immgen.v $(TB_DIR)/immgen_tb.v
INSTR_MEM_DEPS = instr_mem.v $(TB_DIR)/instr_mem_tb.v
PC_DEPS = pc.v $(TB_DIR)/pc_tb.v
PC_UPDATE_DEPS = pc_update.v $(TB_DIR)/pc_update_tb.v
REG_FILE_DEPS = reg_file.v $(TB_DIR)/reg_file_tb.v
DATA_MEM_DEPS = data_mem.v $(TB_DIR)/data_mem_tb.v
WB_MUX_DEPS = wb_mux.v $(TB_DIR)/wb_mux_tb.v
DATAPATH_DEPS = datapath.v alu.v branch_comp.v decoder.v immgen.v instr_mem.v pc.v pc_update.v reg_file.v wb_mux.v data_mem.v $(TB_DIR)/datapath_tb.v

# Default target - run all tests
all: $(TESTBENCHES)

# Ensure build directory exists
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Individual testbench targets
alu_tb: $(ALU_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/alu_tb.vvp $^
	$(VVP) $(BUILD_DIR)/alu_tb.vvp

branch_comp_tb: $(BRANCH_COMP_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/branch_comp_tb.vvp $^
	$(VVP) $(BUILD_DIR)/branch_comp_tb.vvp

decoder_tb: $(DECODER_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/decoder_tb.vvp $^
	$(VVP) $(BUILD_DIR)/decoder_tb.vvp

immgen_tb: $(IMMGEN_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/immgen_tb.vvp $^
	$(VVP) $(BUILD_DIR)/immgen_tb.vvp

instr_mem_tb: $(INSTR_MEM_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/instr_mem_tb.vvp $^
	$(VVP) $(BUILD_DIR)/instr_mem_tb.vvp

pc_tb: $(PC_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/pc_tb.vvp $^
	$(VVP) $(BUILD_DIR)/pc_tb.vvp

pc_update_tb: $(PC_UPDATE_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/pc_update_tb.vvp $^
	$(VVP) $(BUILD_DIR)/pc_update_tb.vvp

reg_file_tb: $(REG_FILE_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/reg_file_tb.vvp $^
	$(VVP) $(BUILD_DIR)/reg_file_tb.vvp

data_mem_tb: $(DATA_MEM_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/data_mem_tb.vvp $^
	$(VVP) $(BUILD_DIR)/data_mem_tb.vvp

wb_mux_tb: $(WB_MUX_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/wb_mux_tb.vvp $^
	$(VVP) $(BUILD_DIR)/wb_mux_tb.vvp

datapath_tb: $(DATAPATH_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/datapath_tb.vvp $^
	$(VVP) $(BUILD_DIR)/datapath_tb.vvp

# Clean up generated files
clean:
	rm -f $(BUILD_DIR)/*.vvp $(BUILD_DIR)/*.vcd *.vcd

# Help target
help:
	@echo "RISC-V Testbench Makefile"
	@echo "=========================="
	@echo "Targets:"
	@echo "  all              - Run all testbenches"
	@echo "  alu_tb           - Test ALU module"
	@echo "  branch_comp_tb   - Test Branch Comparator"
	@echo "  decoder_tb       - Test Instruction Decoder"
	@echo "  immgen_tb        - Test Immediate Generator"
	@echo "  instr_mem_tb     - Test Instruction Memory"
	@echo "  pc_tb            - Test Program Counter"
	@echo "  pc_update_tb     - Test PC Update Logic"
	@echo "  reg_file_tb      - Test Register File"
	@echo "  data_mem_tb      - Test Data Memory"
	@echo "  wb_mux_tb        - Test Write-back Multiplexer"
	@echo "  datapath_tb      - Test Datapath Integration"
	@echo "  clean            - Remove generated files"
	@echo "  help             - Display this help message"

.PHONY: all alu_tb branch_comp_tb decoder_tb immgen_tb instr_mem_tb pc_tb pc_update_tb reg_file_tb data_mem_tb wb_mux_tb datapath_tb clean help
