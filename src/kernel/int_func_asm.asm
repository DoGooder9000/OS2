%define PIC1 0x20
%define PIC2 0xA0
%define PICEOI 0x20

%macro SendPICEOI 0
pusha
mov al, PICEOI
out PIC1, al
popa
%endmacro

global PIT_Interrupt
PIT_Interrupt:
	pusha

	SendPICEOI
	
	popa
	iretd

global Keyboard_Interrupt
Keyboard_Interrupt:
	pusha

	SendPICEOI

	popa
	iretd