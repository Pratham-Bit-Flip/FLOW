VERILOG = iverilog
VVP = vvp
VFLAGS = -g2009

RTL_CORE = rtl/core
RTL_MEMORY = rtl/memory
RTL_PERIPHERALS = rtl/peripherals
RTL_TOP = rtl/top
TB_UNIT = tb/unit
TB_INTEGRATION = tb/integration
BUILD_DIR = artifacts/sim_build

TESTBENCHES = \
	alu_tb \
	branch_comp_tb \
	decoder_tb \
	immgen_tb \
	pc_tb \
	reg_file_tb \
	data_mem_tb \
	wb_mux_tb \
	test_bootrom_tb \
	riscv_top_tb \
	riscv_integration_tb \
	rv32i_led_top_tb

ALU_DEPS = $(RTL_CORE)/alu.v $(TB_UNIT)/alu_tb.v
BRANCH_COMP_DEPS = $(RTL_CORE)/branch_comp.v $(TB_UNIT)/branch_comp_tb.v
DECODER_DEPS = $(RTL_CORE)/decoder.v $(TB_UNIT)/decoder_tb.v
IMMGEN_DEPS = $(RTL_CORE)/immgen.v $(TB_UNIT)/immgen_tb.v
PC_DEPS = $(RTL_CORE)/pc.v $(TB_UNIT)/pc_tb.v
REG_FILE_DEPS = $(RTL_CORE)/reg_file.v $(TB_UNIT)/reg_file_tb.v
DATA_MEM_DEPS = $(RTL_MEMORY)/data_mem.v $(TB_UNIT)/data_mem_tb.v
WB_MUX_DEPS = $(RTL_CORE)/wb_mux.v $(TB_UNIT)/wb_mux_tb.v
BOOTROM_DEPS = $(RTL_MEMORY)/instr_mem.v $(TB_UNIT)/test_bootrom_tb.v
RISCV_TOP_DEPS = $(RTL_TOP)/riscv_top.v $(RTL_CORE)/datapath.v $(RTL_CORE)/alu.v $(RTL_CORE)/branch_comp.v $(RTL_CORE)/decoder.v $(RTL_CORE)/immgen.v $(RTL_MEMORY)/instr_mem.v $(RTL_CORE)/pc.v $(RTL_CORE)/reg_file.v $(RTL_CORE)/wb_mux.v $(RTL_MEMORY)/data_mem.v $(RTL_MEMORY)/mem_map.v $(RTL_MEMORY)/flash_mem.v $(RTL_PERIPHERALS)/uart_mmio.v $(RTL_PERIPHERALS)/uart_tx.v $(RTL_PERIPHERALS)/uart_rx.v $(RTL_PERIPHERALS)/uart_bootloader.v $(TB_INTEGRATION)/riscv_top_tb.v
RISCV_INTEGRATION_DEPS = $(RTL_TOP)/riscv_top.v $(RTL_TOP)/rv32i_soc.v $(RTL_TOP)/rv32i_led_top.v $(RTL_TOP)/led_blink_overlay.v $(RTL_CORE)/datapath.v $(RTL_CORE)/alu.v $(RTL_CORE)/branch_comp.v $(RTL_CORE)/decoder.v $(RTL_CORE)/immgen.v $(RTL_MEMORY)/instr_mem.v $(RTL_CORE)/pc.v $(RTL_CORE)/reg_file.v $(RTL_CORE)/wb_mux.v $(RTL_MEMORY)/data_mem.v $(RTL_MEMORY)/mem_map.v $(RTL_MEMORY)/flash_mem.v $(RTL_PERIPHERALS)/uart_mmio.v $(RTL_PERIPHERALS)/uart_tx.v $(RTL_PERIPHERALS)/uart_rx.v $(RTL_PERIPHERALS)/uart_bootloader.v $(TB_INTEGRATION)/riscv_integration_tb.v
RV32I_LED_TOP_DEPS = $(RTL_TOP)/rv32i_led_top.v $(RTL_TOP)/riscv_top.v $(TB_INTEGRATION)/rv32i_led_top_tb.v

all: $(TESTBENCHES)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

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

pc_tb: $(PC_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/pc_tb.vvp $^
	$(VVP) $(BUILD_DIR)/pc_tb.vvp

reg_file_tb: $(REG_FILE_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/reg_file_tb.vvp $^
	$(VVP) $(BUILD_DIR)/reg_file_tb.vvp

data_mem_tb: $(DATA_MEM_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/data_mem_tb.vvp $^
	$(VVP) $(BUILD_DIR)/data_mem_tb.vvp

wb_mux_tb: $(WB_MUX_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/wb_mux_tb.vvp $^
	$(VVP) $(BUILD_DIR)/wb_mux_tb.vvp

test_bootrom_tb: $(BOOTROM_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/test_bootrom_tb.vvp $^
	$(VVP) $(BUILD_DIR)/test_bootrom_tb.vvp

riscv_top_tb: $(RISCV_TOP_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/riscv_top_tb.vvp $^
	$(VVP) $(BUILD_DIR)/riscv_top_tb.vvp

riscv_integration_tb: $(RISCV_INTEGRATION_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/riscv_integration_tb.vvp $^
	$(VVP) $(BUILD_DIR)/riscv_integration_tb.vvp

rv32i_led_top_tb: $(RV32I_LED_TOP_DEPS) | $(BUILD_DIR)
	$(VERILOG) $(VFLAGS) -o $(BUILD_DIR)/rv32i_led_top_tb.vvp $^
	$(VVP) $(BUILD_DIR)/rv32i_led_top_tb.vvp

clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "RISC-V Testbench Makefile"
	@echo "=========================="
	@echo "Targets:"
	@echo "  all                  - Run all testbenches"
	@echo "  alu_tb               - Test ALU module"
	@echo "  branch_comp_tb       - Test Branch Comparator"
	@echo "  decoder_tb           - Test Instruction Decoder"
	@echo "  immgen_tb            - Test Immediate Generator"
	@echo "  pc_tb                - Test Program Counter"
	@echo "  reg_file_tb          - Test Register File"
	@echo "  data_mem_tb          - Test Data Memory"
	@echo "  wb_mux_tb            - Test Write-back Multiplexer"
	@echo "  test_bootrom_tb      - Test Instruction Memory / boot ROM"
	@echo "  riscv_top_tb         - Test CPU top"
	@echo "  riscv_integration_tb - Test SoC integration"
	@echo "  rv32i_led_top_tb     - Test board wrapper"
	@echo "  clean                - Remove generated files"
	@echo "  help                 - Display this help message"

.PHONY: all alu_tb branch_comp_tb decoder_tb immgen_tb pc_tb reg_file_tb data_mem_tb wb_mux_tb test_bootrom_tb riscv_top_tb riscv_integration_tb rv32i_led_top_tb clean help
