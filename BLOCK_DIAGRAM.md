# RISC-V CPU Block Diagram

## High-Level Architecture

```mermaid
graph TB
    subgraph IF["INSTRUCTION FETCH"]
        PC["Program Counter<br/>(32-bit)"]
        IMEM["Instruction Memory<br/>(1024 words)"]
        PC -->|pc[11:0]| IMEM
        IMEM -->|instr[31:0]| DEC
    end

    subgraph DE["INSTRUCTION DECODE & REGISTER FILE"]
        DEC["Decoder<br/>(RV32I)"]
        REGF["Register File<br/>(32×32-bit)<br/>Dual-port RD<br/>Single-port WR"]
        IMMGEN["Immediate<br/>Generator"]
        
        DEC -->|rs1[4:0]| REGF
        DEC -->|rs2[4:0]| REGF
        REGF -->|rs1_data[31:0]| MUX1
        REGF -->|rs2_data[31:0]| MUX2
        DEC -->|imm_sel[2:0]| IMMGEN
        IMMGEN -->|imm[31:0]| MUX2
        DEC -->|ctrl_signals| EX
    end

    subgraph EX["EXECUTION"]
        MUX1["Mux A<br/>(PC/RS1)"]
        ALU["ALU<br/>(11 ops)"]
        MUX2["Mux B<br/>(RS2/IMM)"]
        BRCOMP["Branch<br/>Comparator"]
        PCNEXT["PC Next<br/>Calculator"]
        
        PC -->|pc[31:0]| MUX1
        MUX1 -->|alu_a[31:0]| ALU
        MUX2 -->|alu_b[31:0]| ALU
        ALU -->|alu_result[31:0]| DMEM_ADDR
        ALU -->|zero| BRCOMP
        REGF -->|rs1/rs2| BRCOMP
        BRCOMP -->|take_branch| PCNEXT
        DEC -->|is_jal, is_jalr, is_branch| PCNEXT
        PCNEXT -->|next_pc[31:0]| PC
    end

    subgraph MEM["DATA MEMORY & I/O"]
        MMAP["Memory Map<br/>Decoder"]
        DMEM_ADDR["Address<br/>Register"]
        DMEM["Data Memory<br/>(256 words)"]
        UART_IO["UART MMIOs<br/>(TX/RX)"]
        LED["LED Output<br/>Register"]
        BOOT["UART<br/>Bootloader"]
        
        ALU -->|dmem_addr[31:0]| MMAP
        MMAP -->|mem_sel| DMEM
        MMAP -->|uart_sel| UART_IO
        MMAP -->|led_sel| LED
        DMEM -->|dmem_rdata[31:0]| WBMUX
        UART_IO -->|uart_rdata[31:0]| WBMUX
        LED -->|led_data[7:0]| FPGA_OUT["FPGA<br/>Outputs"]
        BOOT -->|boot_addr, boot_wdata| IMEM
        DEC -->|mem_read, mem_write| MMAP
    end

    subgraph WB["WRITE-BACK"]
        WBMUX["WB Mux<br/>(4-way)"]
        WBMUX -->|wb_data[31:0]| REGF
        ALU -->|alu_result| WBMUX
        PC -->|pc+4[31:0]| WBMUX
        DEC -->|wb_sel| WBMUX
    end

    subgraph IO["EXTERNAL INTERFACES"]
        CLK["Clock<br/>(100 MHz)"]
        RST["Reset"]
        UART_IN["UART RX<br/>(115200 baud)"]
        UART_OUT["UART TX"]
        
        CLK -->|clk| PC
        CLK -->|clk| REGF
        CLK -->|clk| DMEM
        CLK -->|clk| IMEM
        RST -->|reset| PC
        UART_IN -->|uart_rx| UART_IO
        UART_IN -->|uart_rx| BOOT
        UART_OUT -->|uart_tx| UART_IO
    end

    style IF fill:#e1f5ff
    style DE fill:#f3e5f5
    style EX fill:#fff3e0
    style MEM fill:#e8f5e9
    style WB fill:#fce4ec
    style IO fill:#f1f8e9
```

---

## Datapath - Single Cycle Execution

```mermaid
graph LR
    subgraph FETCH["FETCH STAGE"]
        PC_REG["PC Register"]
        PC_MUX["PC Mux"]
        IMEM["Instruction<br/>Memory"]
        PC_PLUS4["PC + 4"]
    end

    subgraph DECODE["DECODE STAGE"]
        INSTR["Instruction[31:0]"]
        DEC["Decoder<br/>Control Unit"]
        RF["Register File<br/>x0-x31"]
        IMMGEN["Imm<br/>Generator"]
    end

    subgraph EXECUTE["EXECUTE STAGE"]
        MUX_A["A Mux"]
        MUX_B["B Mux"]
        ALU["32-bit ALU<br/>11 Operations"]
        BR["Branch<br/>Comp"]
        PCNEXT_CALC["PC Next<br/>Calculator"]
    end

    subgraph MEMORY["MEMORY STAGE"]
        ADDR_REG["Address"]
        MMAP["Memory<br/>Decoder"]
        DMEM["Data<br/>Memory"]
        IO["I/O<br/>Controller"]
    end

    subgraph WRITEBACK["WRITE-BACK STAGE"]
        WB_MUX["WB Mux<br/>(Result Select)"]
        RF_WR["RF Write"]
    end

    PC_REG -->|0x0000| PC_MUX
    PC_PLUS4 -->|pc+4| PC_MUX
    PCNEXT_CALC -->|branch/jal| PC_MUX
    PC_MUX -->|next_pc| PC_REG
    PC_REG -->|pc[11:0]| IMEM
    IMEM -->|instr[31:0]| INSTR

    INSTR -->|[19:15]| RF
    INSTR -->|[24:20]| RF
    RF -->|rs1_data| MUX_A
    RF -->|rs2_data| MUX_B
    INSTR -->|imm_sel| IMMGEN
    IMMGEN -->|imm[31:0]| MUX_B
    
    DEC -->|sel_a| MUX_A
    DEC -->|sel_b| MUX_B
    MUX_A -->|alu_a| ALU
    MUX_B -->|alu_b| ALU
    
    ALU -->|result[31:0]| ADDR_REG
    ALU -->|result| WB_MUX
    ALU -->|zero| BR
    RF -->|rs1,rs2| BR
    BR -->|take_br| PCNEXT_CALC
    
    DEC -->|is_jal, is_br| PCNEXT_CALC
    PC_REG -->|pc| PCNEXT_CALC
    INSTR -->|imm| PCNEXT_CALC
    
    ADDR_REG -->|dmem_addr| MMAP
    MMAP -->|sel| DMEM
    MMAP -->|sel| IO
    DMEM -->|rdata| WB_MUX
    IO -->|rdata| WB_MUX
    PC_PLUS4 -->|pc+4| WB_MUX
    DEC -->|sel| WB_MUX
    
    WB_MUX -->|wb_data| RF_WR

    style PC_REG fill:#ffcccc
    style IMEM fill:#ccffcc
    style RF fill:#ccccff
    style ALU fill:#ffffcc
    style DMEM fill:#ffccff
    style WB_MUX fill:#ccffff
```

---

## Memory Hierarchy & I/O Subsystem

```mermaid
graph TB
    CPU["CPU Core<br/>(RV32I Execution)"]
    
    CPU -->|pc[11:0]| IMEM["Instruction Memory<br/>(1024 words)<br/>Address: 0x0000_0000"]
    CPU -->|addr[11:0]<br/>we/re| DMEM["Data Memory<br/>(256 words)<br/>Address: 0x0000_0000"]
    CPU -->|addr[15:0]| MMAP["Memory Map<br/>Decoder"]
    
    MMAP -->|0x8000_0000<br/>UART RX/TX| UART["UART Controller<br/>115200 baud<br/>8N1 Format"]
    MMAP -->|0x8000_1000<br/>LED[7:0]| LEDOUT["LED Output<br/>Latch"]
    MMAP -->|0x9000_0000<br/>OPTIONAL| FLASH["Flash Memory<br/>(Optional)<br/>256 words"]
    
    UART -->|uart_tx| FPGA_TX["FPGA Pin<br/>GPIO J21"]
    UART -->|uart_rx| GPIO_RX["GPIO Pin<br/>GPIO K22"]
    
    LEDOUT -->|led[7:0]| LED_PINS["LED Output<br/>LED[7:0]"]
    
    BOOT["UART Bootloader<br/>(Optional)<br/>Timeout: 100M cycles"]
    GPIO_RX -->|uart_rx| BOOT
    BOOT -->|boot_we<br/>boot_addr<br/>boot_wdata| IMEM
    
    CPU -->|debug_pc[31:0]<br/>debug_instr[31:0]<br/>debug_alu[31:0]| DEBUG["Debug Outputs"]
    
    style CPU fill:#fff8e1
    style IMEM fill:#c8e6c9
    style DMEM fill:#c8e6c9
    style UART fill:#bbdefb
    style LEDOUT fill:#f8bbd0
    style BOOT fill:#e1bee7
    style MMAP fill:#ffe0b2
    style DEBUG fill:#d1c4e9
```

---

## Signal Definitions

### Clock & Reset
- **clk**: 100 MHz system clock
- **reset**: Active-high reset signal

### Instruction Memory Interface
- **imem_addr[11:0]**: Address (10 bits for word addressing)
- **imem_rdata[31:0]**: Read instruction data

### Data Memory Interface
- **dmem_addr[31:0]**: Data memory address from ALU
- **dmem_wdata[31:0]**: Data to write
- **dmem_rdata[31:0]**: Data read from memory
- **dmem_we**: Write enable
- **dmem_re**: Read enable
- **dmem_funct3[2:0]**: Access width (byte/halfword/word)

### Register File
- **rs1[4:0], rs2[4:0]**: Source register indices
- **rd[4:0]**: Destination register index
- **rs1_data[31:0], rs2_data[31:0]**: Register read data
- **wb_data[31:0]**: Write-back data
- **reg_write**: Register file write enable

### ALU Interface
- **alu_a[31:0], alu_b[31:0]**: ALU operands
- **alu_op[3:0]**: ALU operation select
- **alu_result[31:0]**: ALU result
- **alu_zero**: Zero flag output

### UART Interface
- **uart_rx**: UART receive pin (GPIO K22)
- **uart_tx**: UART transmit pin (GPIO J21)

### LED Interface
- **led_out[7:0]**: LED output register (memory-mapped @ 0x80001000)

### Debug Outputs
- **pc_out[31:0]**: Current program counter
- **instr_out[31:0]**: Current instruction
- **alu_result_out[31:0]**: ALU result
- **reg_rs1_out, reg_rs2_out[31:0]**: Source register values
- **wb_data_out[31:0]**: Write-back data
- **boot_done_out**: Bootloader finished
- **cpu_running_out**: CPU out of reset
- **boot_rx_seen_out**: UART bootloader detected data

---

## Module Hierarchy

```
rv32i_led_top (Top-level FPGA wrapper)
├── riscv_top (CPU Core)
│   ├── uart_bootloader (UART firmware loader - optional)
│   ├── datapath (Execution engine)
│   │   ├── pc (Program counter)
│   │   ├── decoder (Instruction decoder)
│   │   ├── immgen (Immediate generator)
│   │   ├── reg_file (32×32-bit register file)
│   │   ├── alu (32-bit ALU)
│   │   ├── branch_comp (Branch condition evaluator)
│   │   └── wb_mux (Write-back multiplexer)
│   ├── instr_mem (Instruction memory - 1 KB)
│   └── mem_map (Memory decoder + I/O)
│       ├── data_mem (Data memory - 1 KB)
│       ├── uart_mmio (UART controller)
│       ├── uart_tx (UART transmitter)
│       ├── uart_rx (UART receiver)
│       └── flash_mem (Optional flash - 1 KB)
└── LED output mapping
```

---

## Memory Map

```
Address Range           Segment          Size      Access
────────────────────────────────────────────────────────────
0x00000000 - 0x000003FF  Instr Memory    4 KB     Read (boot), Write (bootloader)
0x00000000 - 0x000003FF  Data Memory     1 KB     Read/Write
0x80000000              UART RX/TX       4 B      Read/Write
0x80001000              LED Output       4 B      Write
0x90000000 - 0x900003FF  Flash Mem       1 KB     Read (optional)
```

---

## Instruction Execution Example

### Example: Write 0xFF to LED (ledtest.c)

```assembly
# lui x15, 0x80001       # Load upper immediate: x15 = 0x80001000
# addi x14, x0, 0xff     # Add immediate: x14 = 0xff
# sw x14, 0(x15)         # Store word: M[0x80001000] = 0xff
# jal x0, 0              # Jump and link to self (infinite loop)
```

**Execution Timeline:**
```
Cycle 1:
  PC = 0x00000000
  Fetch: instr = 0x800017b7 (lui x15, 0x80001)
  Decode: rd=x15, imm=0x80001, alu_op=LUI
  ALU: alu_result = 0x80001000
  WB: x15 = 0x80001000
  PC_next = 0x00000004

Cycle 2:
  PC = 0x00000004
  Fetch: instr = 0x0ff00713 (addi x14, x0, 0xff)
  Decode: rd=x14, rs1=x0, imm=0xff, alu_op=ADD
  ALU: alu_result = 0x00 + 0xff = 0xff
  WB: x14 = 0xff
  PC_next = 0x00000008

Cycle 3:
  PC = 0x00000008
  Fetch: instr = 0x00e7a023 (sw x14, 0(x15))
  Decode: rs1=x15, rs2=x14, imm=0, mem_write=1
  ALU: alu_result = 0x80001000 + 0 = 0x80001000
  Memory: Write 0xff to address 0x80001000
  LED register updates: LED[7:0] = 0xff → ALL LEDs ON
  PC_next = 0x0000000c

Cycle 4:
  PC = 0x0000000c
  Fetch: instr = 0x0000006f (jal x0, 0)
  Decode: rd=x0 (discard), imm=0, is_jal=1
  ALU: (not used for jal)
  PC_next = pc + imm = 0x0000000c + 0 = 0x0000000c (infinite loop)

Cycle 5+:
  PC = 0x0000000c (stuck in infinite loop)
  Instruction at 0x0000000c keeps fetching and executing (no-op loop)
```

---

**This document defines the complete architecture. Open in any Markdown viewer (VS Code, GitHub, etc.)**
