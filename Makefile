# Makefile for Artix-7 (xc7a50t) 
# Flow: Yosys + nextpnr-xilinx + prjxray + openFPGALoader

# Tools
YOSYS          = yosys
NEXTPNR        = ~/nextpnr-xilinx-install/bin/nextpnr-xilinx
XC7FRAMES2BIT  = ~/prjxray-install/bin/xc7frames2bit
OPENFPGALOADER = openFPGALoader

# FPGA part (Numato Mimas A7, xc7a50t-fgg484-1)
DEVICE     = xc7a50t-1fgg484
CHIPDB     = ~/nextpnr-xilinx/build/xilinx/chipdb-$(DEVICE).bin

# files
TOP        = top
SRC        = LED_BLINK/top.v LED_BLINK/led_blink.v
XDC        = boards/xillinx/numato_io.xdc
BUILD_DIR  = build

# Outputs
JSON       = $(BUILD_DIR)/$(TOP).json
FASM       = $(BUILD_DIR)/$(TOP).fasm
BIT        = $(BUILD_DIR)/$(TOP).bit

all: $(BIT)

# Step 1: Synthesis with Yosys
$(JSON): $(SRC)
	mkdir -p $(BUILD_DIR)
	$(YOSYS) -p "read_verilog $(SRC); synth_xilinx -top $(TOP) -json $(JSON)"

# Step 2: Place and route with nextpnr-xilinx
$(FASM): $(JSON) $(XDC)
	$(NEXTPNR) --chipdb $(CHIPDB) \
	           --json $(JSON) \
	           --xdc $(XDC) \
	           --fasm $(FASM) 

# Step 3: Convert FASM to bitstream
$(BIT): $(FASM)
	$(XC7FRAMES2BIT) --part $(DEVICE) --bit $(BIT) $(FASM)

# Step 4: Program FPGA
prog: $(BIT)
	$(OPENFPGALOADER) -b mimas_a7 $(BIT)

# Utility targets
clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "Makefile targets:"
	@echo "  make all     -> Build bitstream"
	@echo "  make prog    -> Program FPGA"
	@echo "  make clean   -> Delete build directory"
