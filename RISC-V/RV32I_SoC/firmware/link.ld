OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 1K
}

SECTIONS
{
    .text : {
        KEEP(*(.init))
        *(.text*)
        *(.rodata*)
    } > ROM

    .data : {
        *(.data*)
    } > RAM

    .bss (NOLOAD) : {
        *(.bss*)
        *(COMMON)
    } > RAM

    . = ALIGN(16);
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
