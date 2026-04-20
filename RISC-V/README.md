# RISC-V Core Project

This directory is organized using the same clean structure as CorrectM.

## Structure

- `firmware/` : firmware assets, linker/startup, UART uploader, example apps
- `rtl/` : Verilog RTL source files
- `sim/` : testbenches and simulation scripts
- `flows/04_prjxray_numato_mimas_a7_50t/` : build script + board constraints
- `docs/` : bootloader, simulation and memory-map documentation

## Quick Notes

- RTL sources are in `rtl/`.
- Testbenches are in `sim/`.
- Constraints are in `flows/04_prjxray_numato_mimas_a7_50t/constraints/`.
