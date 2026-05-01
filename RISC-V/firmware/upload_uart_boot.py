#!/usr/bin/env python3
"""Upload a firmware binary to the RV32I UART bootloader.

Protocol:
  [len:4 LE][entry:4 LE][payload bytes]
"""

from __future__ import annotations

import argparse
import pathlib
import struct
import sys
import time


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Upload firmware over UART boot protocol")
    parser.add_argument("--port", required=True, help="Serial port (example: /dev/ttyUSB0)")
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate")
    parser.add_argument("--bin", dest="bin_path", default="firmware.bin", help="Path to firmware binary")
    parser.add_argument("--entry", type=lambda x: int(x, 0), default=0, help="Entry address (default: 0)")
    parser.add_argument("--pre-delay", type=float, default=0.1, help="Delay before send (seconds)")
    parser.add_argument("--post-delay", type=float, default=0.05, help="Delay after send (seconds)")
    parser.add_argument("--repeat", type=int, default=1, help="Number of times to send the packet")
    parser.add_argument("--interval", type=float, default=0.02, help="Delay between repeated sends (seconds)")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()

    try:
        import serial  # type: ignore
    except Exception:
        print("ERROR: pyserial is required. Install with: pip install pyserial", file=sys.stderr)
        return 2

    bin_path = pathlib.Path(args.bin_path)
    if not bin_path.is_file():
        print(f"ERROR: Binary not found: {bin_path}", file=sys.stderr)
        return 2

    payload = bin_path.read_bytes()
    header = struct.pack("<II", len(payload), args.entry)
    packet = header + payload

    print(f"[uart-upload] Port: {args.port}")
    print(f"[uart-upload] Baud: {args.baud}")
    print(f"[uart-upload] Binary: {bin_path}")
    print(f"[uart-upload] Length: {len(payload)} bytes")
    print(f"[uart-upload] Entry: 0x{args.entry:08x}")
    print("[uart-upload] Tip: press reset on the board just before upload if needed.")

    if args.repeat < 1:
        print("ERROR: --repeat must be >= 1", file=sys.stderr)
        return 2

    with serial.Serial(args.port, args.baud, timeout=1) as ser:
        time.sleep(args.pre_delay)
        for idx in range(args.repeat):
            written = ser.write(packet)
            ser.flush()
            if written != len(packet):
                print(f"ERROR: Wrote {written} / {len(packet)} bytes on attempt {idx + 1}", file=sys.stderr)
                return 1
            if idx + 1 < args.repeat:
                time.sleep(args.interval)
        time.sleep(args.post_delay)

    if args.repeat == 1:
        print("[uart-upload] Upload complete")
    else:
        print(f"[uart-upload] Upload complete ({args.repeat} packets sent)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
