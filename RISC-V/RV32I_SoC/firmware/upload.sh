#!/usr/bin/env bash
# ------------------------------------------------------------------
#  upload.sh  —  Compile & upload C firmware to the RV32I SoC via UART
#
#  Usage:
#    ./upload.sh                      # uploads ping_pong (default)
#    ./upload.sh led_showcase          # uploads led_showcase
#    ./upload.sh my_app                # uploads my_app.c
#    ./upload.sh my_app /dev/ttyUSB1   # use a different serial port
#
#  The FPGA bitstream (with UART bootloader) is already in SPI flash.
#  Just edit your .c file, run this script, and press reset on the board.
# ------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="${1:-ping_pong}"
PORT="${2:-/dev/ttyUSB0}"
BAUD="${3:-115200}"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   RV32I UART Firmware Upload                 ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  App:  ${APP}"
echo "║  Port: ${PORT}"
echo "║  Baud: ${BAUD}"
echo "╚══════════════════════════════════════════════╝"
echo ""

cd "$SCRIPT_DIR"

echo "[1/2] Compiling ${APP}.c → firmware.bin ..."
make APP="$APP" clean all 2>&1 | tail -3

SIZE=$(stat --format="%s" firmware.bin 2>/dev/null || stat -f%z firmware.bin 2>/dev/null)
echo "      Binary size: ${SIZE} bytes"
echo ""

echo "[2/2] Uploading via UART (press board RESET now if needed) ..."
python3 upload_uart_boot.py \
    --port "$PORT" \
    --baud "$BAUD" \
    --bin firmware.bin \
    --entry 0 \
    --repeat 40 \
    --interval 0.05

echo ""
echo "✅ Done! Press RESET on the board if LEDs don't start."
echo ""
