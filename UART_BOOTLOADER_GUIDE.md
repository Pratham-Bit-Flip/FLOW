# UART Bootloader Guide

## Overview

The RISC-V CPU core has an **integrated UART bootloader** that enables **dynamic firmware upload** via USB without rebuilding the FPGA bitstream.

### Key Features:
- ✅ **No external UART adapter needed** - FT2232HL USB bridge is on the Mimas A7 board
- ✅ **115200 baud, 8N1 format** - Standard serial communication
- ✅ **50ms + 1 second timeout** - Automatic timeout for flexibility
- ✅ **USB connection** - Direct PC-to-FPGA via FT2232HL
- ✅ **LED indicators** - Visual feedback during boot process
- ✅ **Production-ready** - Enabled by default, always active

---

## Hardware Setup

### USB Connection
```
PC (USB Port)
    ↓
[USB Cable - Type-A to Micro-B]
    ↓
Mimas A7 Board (FT2232HL USB Bridge)
    ↓
GPIO J21 (uart_rx) ← RX data
GPIO K22 (uart_tx) → TX data
    ↓
CPU UART Controller
    ↓
Bootloader (100M cycle timeout)
    ↓
Instruction Memory (firmware upload)
    ↓
CPU Execution
```

### GPIO Pin Mapping
| Signal | GPIO | FPGA Pin | Function |
|--------|------|----------|----------|
| uart_rx | J21 | J21 | Receive data from PC |
| uart_tx | K22 | K22 | Send data to PC |

**No jumpers or external adapters required.** The FT2232HL is integrated on the board.

---

## LED Status Indicators

During boot, LEDs provide real-time feedback:

| LED | Pin | Status | Meaning |
|-----|-----|--------|---------|
| LED[7] | K17 | Blinking | FPGA alive (heartbeat) |
| LED[6] | J17 | Pulse | UART activity detected |
| LED[5] | L14 | ON | Bootloader received UART byte |
| LED[4] | L15 | ON | CPU released from reset (boot done) |
| LED[3:0] | - | App-controlled | Firmware output |

**Typical boot sequence:**
1. Power on → LED[7] blinking (FPGA alive)
2. Open serial terminal (115200 baud)
3. Send firmware → LED[5] lights (UART detected)
4. Wait 50ms idle → LED[4] lights (CPU released)
5. Firmware executes → LED[3:0] reflect application state

---

## Software Setup

### Linux/Mac

#### 1. Identify USB Device
```bash
ls -la /dev/ttyUSB*
# Output: /dev/ttyUSB0 or /dev/ttyUSB1

# Verify it's the right device:
udevadm info -q all -n /dev/ttyUSB0 | grep PRODUCT
# Should show FT2232H (Numato)
```

#### 2. Set USB Permissions (first time only)
```bash
# Add user to dialout group for USB serial access
sudo usermod -a -G dialout $USER

# Log out and back in, or:
newgrp dialout
```

#### 3. Install Serial Terminal (choose one)
```bash
# Option A: picocom (lightweight)
sudo apt install picocom
picocom -b 115200 /dev/ttyUSB0

# Option B: minicom (full-featured)
sudo apt install minicom
minicom -b 115200 -D /dev/ttyUSB0

# Option C: screen (minimalist)
sudo apt install screen
screen /dev/ttyUSB0 115200

# Option D: Python (script-friendly)
pip install pyserial
python3 -c "import serial; s=serial.Serial('/dev/ttyUSB0', 115200); print(s.read())"
```

#### 4. Send Firmware Manually (picocom)
```bash
# Open terminal
picocom -b 115200 /dev/ttyUSB0

# In picocom, press Ctrl+D to send file (binary upload mode)
# Select firmware binary file
# Wait for timeout (LED[4] lights)
# Firmware executes

# Exit: Ctrl+A, Ctrl+X
```

### Windows

#### 1. Identify COM Port
```cmd
# Device Manager → Ports (COM & LPT)
# Look for "FTDI USB UART" or "Numato Mimas A7"
# Note the COM port (e.g., COM3)
```

#### 2. Install Terminal Software (choose one)
```
- PuTTY (free): https://putty.org
- Tera Term (free): https://teratermproject.github.io
- RealTerm (free): https://realterm.sourceforge.io
- TeraTerm (simple): https://github.com/TeraTermProject/teraterm
```

#### 3. Configure Serial Port
```
- Baud Rate: 115200
- Data Bits: 8
- Stop Bits: 1
- Parity: None
- Flow Control: None
- Port: COM3 (or identified COM port)
```

#### 4. Send Firmware
```
In PuTTY/Tera Term:
1. Connect to COM port
2. See LED[7] blinking (FPGA alive)
3. File → Send Binary File → Select .bin firmware
4. Wait for timeout (LED[5] then LED[4] light)
5. Firmware executes
```

---

## Firmware Upload Protocol

### Protocol Details
- **Format**: Raw 32-bit words, **little-endian byte order**
- **Baud Rate**: 115200 bps, 8N1
- **Timing**: 
  - Per-word: 50 ms idle timeout
  - Absolute: 100M cycles (~1 second) maximum
- **Target**: Instruction Memory (IMEM) starting at address 0x00000000

### Byte-Level Transmission
```
Bootloader expects bytes in this order:
Byte 0 (LSB) → bits[7:0] of instruction word
Byte 1       → bits[15:8]
Byte 2       → bits[23:16]
Byte 3 (MSB) → bits[31:24]

After 4 bytes received:
→ Assemble 32-bit word (little-endian)
→ Write to IMEM[address]
→ address += 1
→ Reset idle timeout
```

### Example: Uploading LED Test
```bash
# Compile firmware to binary
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -o firmware.elf ledtest.c
riscv64-unknown-elf-objcopy -O binary firmware.elf firmware.bin

# Check binary size (must fit in 4 KB)
ls -l firmware.bin  # Should be < 4096 bytes

# Send binary via picocom
picocom -b 115200 /dev/ttyUSB0
# Ctrl+D to send file
# Select firmware.bin
# Wait 1 second for timeout
# Firmware executes!
```

---

## Practical Examples

### Example 1: Simple LED Toggle

**ledtest.c:**
```c
#define LED_BASE 0x80001000
volatile int *led = (int *)LED_BASE;

int main() {
    *led = 0xFF;  // All LEDs ON
    while (1) {
        // Infinite loop
    }
    return 0;
}
```

**Compile & Upload:**
```bash
cd FLOW/RISC-V/RV32I_SoC/firmware

# Build
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -Os \
  -ffreestanding -nostdlib -nostartfiles \
  -T link.ld crt0.S ledtest.c -o firmware.elf
riscv64-unknown-elf-objcopy -O binary firmware.elf firmware.bin

# Check size
ls -l firmware.bin

# Upload
picocom -b 115200 /dev/ttyUSB0
# Ctrl+D → firmware.bin → Wait → Firmware executes
```

### Example 2: UART Loopback Echo

**uart_loopback.c:**
```c
#define UART_BASE 0x80000000
volatile int *uart = (int *)UART_BASE;

int main() {
    while (1) {
        int c = *uart;        // Read from UART (RX)
        *(uart + 1) = c;      // Write to UART (TX) - echo back
    }
    return 0;
}
```

**Test:**
```bash
# Compile & upload same as above
# Then in terminal:
# Type characters → They echo back
```

### Example 3: Counter Program

**counter.c:**
```c
#define LED_BASE 0x80001000
volatile int *led = (int *)LED_BASE;

int main() {
    int count = 0;
    while (1) {
        *led = count & 0xFF;  // Show lower 8 bits on LEDs
        count++;
        // Delay loop (software)
        for (int i = 0; i < 1000000; i++);
    }
    return 0;
}
```

---

## Troubleshooting

### Issue: "Cannot open /dev/ttyUSB0"
**Solution:**
```bash
# Check if device exists
ls -la /dev/ttyUSB*

# If not found, check FTDI driver
lsusb | grep -i ftdi

# Reinstall driver
sudo apt install libftdi-dev

# Try unplugging USB and replugging
```

### Issue: Bootloader Timeout (never releases CPU)
**Possible Causes:**
1. USB cable not connected
2. Wrong baud rate (must be 115200)
3. UART pins incorrectly wired
4. FT2232HL not recognized by OS

**Solutions:**
```bash
# Verify UART is working
cat /dev/ttyUSB0
# Should show data when typing (or timeout if no data)

# Check dmesg for errors
dmesg | tail -20

# Verify FTDI device detected
lsusb | grep FTDI
```

### Issue: Firmware Doesn't Execute After Upload
**Possible Causes:**
1. Firmware binary corrupted during transmission
2. Instruction memory not properly written
3. CPU reset not released by bootloader

**Solutions:**
1. Verify file size: must be < 4096 bytes (4 KB)
2. Check LED[4] lights (confirms CPU released)
3. Add debug output to firmware
4. Check instruction memory synthesis (see CPU issues section)

### Issue: LED[5] Never Lights (bootloader not receiving)
**Possible Causes:**
1. UART RX pin not connected
2. USB cable loose or broken
3. FT2232HL driver not loaded
4. Wrong serial port

**Solutions:**
```bash
# Test serial connection
picocom -b 115200 /dev/ttyUSB0
# Type: should see local echo

# If no echo, check driver:
lsmod | grep ftdi

# If not loaded, load it:
sudo modprobe ftdi_sio
```

---

## Advanced: Scripted Firmware Upload

### Python Script for Automated Upload
```python
#!/usr/bin/env python3
import serial
import sys
import time

def upload_firmware(port, baud, firmware_file):
    """Upload firmware via UART bootloader"""
    
    # Open serial port
    ser = serial.Serial(port, baud, timeout=2)
    time.sleep(0.5)  # Wait for port to stabilize
    
    # Read firmware binary
    with open(firmware_file, 'rb') as f:
        firmware = f.read()
    
    print(f"Uploading {len(firmware)} bytes to {port} @ {baud} baud")
    
    # Send firmware bytes
    bytes_sent = 0
    for byte in firmware:
        ser.write(bytes([byte]))
        bytes_sent += 1
        if bytes_sent % 100 == 0:
            print(f"  {bytes_sent} bytes sent...")
    
    print(f"Firmware upload complete. Waiting for bootloader timeout...")
    time.sleep(1.5)  # Wait for bootloader timeout
    
    ser.close()
    print("Done! Firmware should now be executing.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python upload.py <firmware.bin> [port] [baud]")
        sys.exit(1)
    
    firmware_file = sys.argv[1]
    port = sys.argv[2] if len(sys.argv) > 2 else "/dev/ttyUSB0"
    baud = int(sys.argv[3]) if len(sys.argv) > 3 else 115200
    
    upload_firmware(port, baud, firmware_file)
```

**Usage:**
```bash
python3 upload.py firmware.bin /dev/ttyUSB0 115200
```

---

## Production Checklist

Before deploying firmware:

- ✅ Bootloader enabled (`WITH_UART_BOOT = 1'b1`)
- ✅ UART pins correctly mapped (J21 = RX, K22 = TX)
- ✅ 115200 baud rate configured
- ✅ Firmware binary < 4 KB
- ✅ USB cable connected and FT2232HL detected
- ✅ Serial port identified (`/dev/ttyUSB0` or `COM3`)
- ✅ LED[4] lights after 1 second (CPU released)
- ✅ Firmware executes as expected

---

## Performance Notes

- **Upload Time**: ~1-2 seconds for 4 KB firmware @ 115200 baud
- **Bootloader Overhead**: 100M cycles (~1 second) maximum
- **Flash to Execution**: 2 seconds end-to-end
- **Memory Limit**: 4 KB instruction memory (firmware size < 4096 bytes)

---

## See Also

- [ARCHITECTURE_SPECIFICATION.md](ARCHITECTURE_SPECIFICATION.md) - Full CPU spec
- [BLOCK_DIAGRAM.md](BLOCK_DIAGRAM.md) - Datapath diagrams
- [Mimas A7 User Manual](https://numato.com/product/mimas-a7-artix-7-fpga-development-board/) - Board details
- [FT2232H Datasheet](https://ftdichip.com/products/ft2232h/) - USB bridge specs

---

**Document Version**: 1.0  
**Last Updated**: April 25, 2026  
**Status**: ✅ Production Ready
