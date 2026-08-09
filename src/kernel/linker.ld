ENTRY(start)

SECTIONS
{
. = 0x18000;
.text : { *(.text) }
.rodata : { *(.rodata) }
.data : { *(.data) }
.bss : { *(.bss) }

. = ALIGN(512);
}