## FLOW

This repository hosts a cleaned, open-source FPGA workflow centered on the RV32I SoC project in [FLOW/RISC-V/RV32I_SoC](FLOW/RISC-V/RV32I_SoC).

The current layout is:

- [FLOW](FLOW) for the FPGA workflow and build guides
- [FLOW/RISC-V/RV32I_SoC](FLOW/RISC-V/RV32I_SoC) for the reorganized SoC RTL, firmware, testbenches, and flows
- [tools](tools) for external dependencies such as `nextpnr-xilinx`, `prjxray`, and `prjxray-db`
- [ARCHITECTURE_SPECIFICATION.md](ARCHITECTURE_SPECIFICATION.md), [BLOCK_DIAGRAM.md](BLOCK_DIAGRAM.md), and [UART_BOOTLOADER_GUIDE.md](UART_BOOTLOADER_GUIDE.md) for project documentation

## What Works

- RV32I hardcoded CPU path on board: working
- Numato Mimas A7 bitstream generation: working
- Unit and integration simulation: available under [FLOW/RISC-V/RV32I_SoC/tb](FLOW/RISC-V/RV32I_SoC/tb)
- UART bootloader path: present and still under debug/tuning

## Quick Start

```bash
cd FLOW/RISC-V/RV32I_SoC/flows/04_prjxray_numato_mimas_a7_50t/scripts
FIRMWARE_APP=ping_pong ./run_prjxray_numato_ppa.sh
```

The generated bitstream is written to [FLOW/RISC-V/RV32I_SoC/flows/04_prjxray_numato_mimas_a7_50t/build/top.bit](FLOW/RISC-V/RV32I_SoC/flows/04_prjxray_numato_mimas_a7_50t/build/top.bit).

For the full flow description, toolchain details, and build results, see [FLOW/README.md](FLOW/README.md).

