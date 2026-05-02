# RISC-V RV32I SoC Project

This repository contains the **RV32I RISC-V soft processor** implementation and supporting tools.

## Structure

```
RISC-V/
├── RV32I_SoC/          (Main project)
│   ├── rtl/            (Verilog RTL source code)
│   ├── tb/             (Testbenches)
│   ├── firmware/       (C firmware apps, linker, startup)
│   ├── flows/          (FPGA build flows and constraints)
│   ├── scripts/        (Simulation and build scripts)
│   ├── artifacts/      (Generated outputs)
│   ├── init/           (Memory initialization files)
│   ├── docs/           (Documentation)
│   ├── legacy/         (Unused/experimental code)
│   ├── Makefile        (Testbench compilation)
│   └── README.md       (Main project documentation)
└── README.md           (This file)
```

## Quick Start

See [RV32I_SoC/README.md](RV32I_SoC/README.md) for comprehensive documentation and usage instructions.

## Key Features

- ✅ **RV32I ISA Implementation** - Full 32-bit RISC-V base instruction set
- ✅ **UART Bootloader** - Load firmware over serial without FPGA reprogramming
- ✅ **Memory-Mapped I/O** - LED control, UART interface
- ✅ **FPGA Flows** - Yosys + nextpnr + prjxray toolchain
- ✅ **Comprehensive Tests** - Unit and integration testbenches

## Building & Testing

```bash
cd RV32I_SoC

# Run all testbenches
make all

# Build FPGA bitstream
cd flows/04_numato_mimas_a7/scripts
./run_prjxray_numato_ppa.sh

# Upload firmware over UART
cd firmware
make APP=ping_pong uart-upload PORT=/dev/ttyUSB0
```

For detailed instructions, see [RV32I_SoC/README.md](RV32I_SoC/README.md).
