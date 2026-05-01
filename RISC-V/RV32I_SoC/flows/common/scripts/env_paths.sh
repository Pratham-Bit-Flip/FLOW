#!/usr/bin/env bash
# Common environment paths for open-source FPGA flows

# Project root (RV32I_SoC)
CORE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export CORE_ROOT

# Flow roots
export FLOW_ROOT="$CORE_ROOT/flows"
export FLOW_FUNC="$FLOW_ROOT/00_functional_iverilog"
export FLOW_ICE40="$FLOW_ROOT/01_icestorm_up5k"
export FLOW_A7="$FLOW_ROOT/02_prjxray_arty_a7_100t"
export FLOW_NUMATO="$FLOW_ROOT/04_prjxray_numato_mimas_a7_50t"

# External tool databases
# Set PRJXRAY_DB_ROOT environment variable before running build scripts
# Example: export PRJXRAY_DB_ROOT=~/tools/prjxray-db
if [ -z "$PRJXRAY_DB_ROOT" ]; then
    echo "WARNING: PRJXRAY_DB_ROOT not set. Please configure the environment variable."
fi
export PRJXRAY_DB_ROOT

# Target parts
export ICE40_PART="up5k"
export ICE40_PACKAGE="uwg30"
export A7_PART="xc7a100tcsg324-1"
export NUMATO_PART="xc7a50tfgg484-1"

# Optional board aliases
export BOARD_ICE40="ice40UP5K-UWG30"
export BOARD_A7="arty-a7-100t"
export BOARD_NUMATO="numato-mimas-a7-50t"
