ENTRY(kernel_entry)

SECTIONS
{
. = 0x18000;
.text : { *(.text.entry) *(.text) }
.rodata : { *(.rodata) }
.data : { *(.data) }
.bss : { *(.bss) }

. = ALIGN(512);
}