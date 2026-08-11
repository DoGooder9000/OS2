bits 32

section .text.entry
global kernel_entry

extern main

kernel_entry:
	call main

hang:
	jmp hang