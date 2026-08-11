bits 32

%define PIC1 0x20
%define PIC2 0xA0
%define PICEOI 0x20

%macro SendPICEOI 0
pusha
mov al, PICEOI
out PIC1, al
popa
%endmacro
%macro SendPIC2EOI 0
pusha
mov al, PICEOI
out PIC2, al
popa
%endmacro

global PIT_Interrupt
PIT_Interrupt:
	pusha

	SendPICEOI
	
	popa
	iretd

extern Keyboard_Interrupt_C
global Keyboard_Interrupt
Keyboard_Interrupt:
	pusha

	xor eax, eax
	in al, 0x60

	push eax
	call Keyboard_Interrupt_C
	add esp, 4

	SendPICEOI

	popa
	iretd

global ATA_Interrupt_Primary
ATA_Interrupt_Primary:
	pusha

	SendPICEOI
	SendPIC2EOI

	popa
	iretd