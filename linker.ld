OUTPUT_FORMAT("elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(_rom_reset)

ROM_BASE = 0x00F80000;
ROM_SIZE = 0x00080000;

MEMORY
{
    ROM (rx) : ORIGIN = ROM_BASE, LENGTH = ROM_SIZE
}

SECTIONS
{
    . = ROM_BASE;

    .vectors :
    {
        KEEP(*(.vectors))
    } > ROM

    .text :
    {
        *(.text.boot)
        *(.text*)
        *(.rodata*)
    } > ROM

    . = ALIGN(4);
    _rom_payload_end = .;

    /DISCARD/ :
    {
        *(.comment*)
        *(.note*)
        *(.eh_frame*)
        *(.data*)
        *(.bss*)
    }

    ASSERT(_rom_payload_end <= ROM_BASE + ROM_SIZE, "AmiDiag ROM exceeds 512 KiB")
}
