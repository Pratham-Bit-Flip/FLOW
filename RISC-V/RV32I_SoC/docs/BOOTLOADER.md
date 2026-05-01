# UART Bootloader Protocol

The UART bootloader downloads a program into instruction RAM, then releases CPU reset. The CPU starts executing from address 0.

## UART Settings

- Baud: 115200 (default)
- Format: 8N1

## Packet Format (little-endian)

1. **Length** (4 bytes): number of payload bytes
2. **Entry** (4 bytes): entry address (must be 0 for this design)
3. **Payload** (N bytes): raw instruction bytes (little-endian per 32-bit word)

## Notes

- The bootloader writes incoming bytes directly into instruction RAM.
- If entry is non-zero and within ±1MB, the bootloader patches address 0 with a `JAL x0, entry`.
- After download, CPU reset is released and execution starts.

## Numato Mimas A7 GPIO UART Mapping

- `uart_rx` -> B4 (`GPIO_1_N`) -> FPGA pin `J21`
- `uart_tx` -> B5 (`GPIO_2_N`) -> FPGA pin `K22`

Cross-connect to external USB-UART module:

- Module TX -> Board B4 (`uart_rx`)
- Module RX -> Board B5 (`uart_tx`)
- GND -> GND

## Firmware-Only Update Flow (No FPGA Rebuild)

1. Program FPGA bitstream once with UART boot enabled.
2. For each C change, run:

```bash
cd firmware
make APP=led_showcase uart-upload PORT=/dev/ttyUSB0 BAUD=115200
```

If the core is already running an old image, press board reset and run upload again.

## Example

For an 8-word program (32 bytes):

- Length: 0x00000020
- Entry:  0x00000000
- Payload: 32 bytes of instruction data (little-endian)
