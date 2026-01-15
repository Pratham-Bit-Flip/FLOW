## FLOW FPGA LOGIC OPEN WORKFLOW

A fully open-source FPGA and processor development project demonstrating an end-to-end hardware design workflow — from basic FPGA bring-up (LED blink) to a verified RISC-V RV32I processor core, using only open-source EDA tools.
FPGA implementation and ISA extensions are actively in progress.

---
### Project Scope

FLOW FPGA LOGIC OPEN WORKFLOW focuses on showing a realistic, reproducible hardware workflow, not just a final CPU core. The project progresses through clearly defined engineering stages:

- FPGA bring-up and toolchain validation

- RTL design and verification

- Synthesis and netlist inspection

- FPGA place-and-route (nextpnr)

- Hardware execution and extensions

Every stage is version-controlled and backed by verification.

---
Repository Structure
```FLOW-FPGA-LOGIC-OPEN-2WORKFLOW/
│
├── README.md
├── Makefile
├── docs/
├── src/
├── tb/
├── boards/
└── tools/
```

---
### Key Facts:

`Toolchain`: 100% open-source

`FPGA Bring-up`: LED blink — ✅ complete

`RISC-V RV32I`: RTL + verification + netlist — ✅ complete

`Netlist Visualization`: SVG via netlistsvg — ✅ complete

`FPGA P&R (nextpnr)`: 🚧 in progress

`ISA Extensions`: 🚧 in progress

---
### Why This Project Exists

Hardware designs are often shared either as isolated RTL or as FPGA binaries without visibility into intermediate steps.
This project bridges that gap by explicitly tracking the full development path:

`RTL → Synthesis → Netlist → FPGA P&R → Hardware`

All stages use open-source tooling, allowing inspection and modification at every level.

---

### Implemented ISA
Base ISA — RV32I (Complete)

R-Type
```ADD, SUB, AND, OR, XOR, SLL, SRL, SRA```


I-Type
```ADDI, ANDI, ORI, XORI, LW```


S-Type
```SW```


B-Type
```BEQ, BNE, BLT, BGE, BLTU, BGEU```

RV32I functionality is fully implemented and verified up to synthesis netlist level.

