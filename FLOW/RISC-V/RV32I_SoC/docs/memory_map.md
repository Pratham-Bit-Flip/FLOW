# Memory Map

| Region | Base Address | Size | Notes |
|---|---:|---:|---|
| RAM | 0x0000_0000 | 1 KB | Data RAM (byte/half/word) |
| Boot ROM | 0x0000_0000 | 256 B | Instruction fetch only (bootrom.hex) |
| UART | 0x8000_0000 | 256 B | MMIO registers |
| LED | 0x8000_1000 | 4 B | LED MMIO register |
| Flash | 0x9000_0000 | 1 KB | Memory-mapped flash model |

## UART MMIO Registers

- **0x8000_0000 TXDATA (W):** write byte to transmit
- **0x8000_0004 STATUS (R):** bit0 = tx_ready, bit1 = rx_valid
- **0x8000_0008 RXDATA (R):** read received byte (clears rx_valid)

## Notes

- Boot ROM is loaded from **bootrom.hex** by instr_mem.
- Flash model is initialized from **flash.hex** and allows writes in simulation.
