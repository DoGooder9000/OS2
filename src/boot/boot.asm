BITS 16
ORG 0x7C00

%define ENDL 0x0D, 0x0A

jmp start

print: ; Put the address of the line in SI
	push ax		; Store AX on the stack
	push si		; Store SI on the stack	
	
	jmp .printloop	; Goto .printloop

.printloop:
	lodsb		; Load the byte at DS:SI into AL ( lower half of AX )
	
	or al, al	; Check if AL is 0 ( End of the string )
	jz .printdone	; If AL is 0 jmp to .printdone

	mov ah, 0x0E	; Set the interrupt code for TTY Character Output
	int 0x10	; Call interrupt 0x10

	jmp .printloop

.printdone:
	pop si		; Put the previous value of SI back into SI
	pop ax		; Put the previous value of AX back into AX
	ret		; Return

start:
	xor ax, ax

	; Data segment registers

	; Segment Registers:
	; SS - Stack Segment Register
	; CS - Code Segment Register
	; DS - Data Segment Register
	; ES - Extra Data Segment Register
	; FS - More Extra Data Segment Register
	; GS - Even More Extra Data Segment Register

	mov ds, ax	; Set the Data Segment Register to 0
	mov es, ax	; Set the Extra Segment Register to 0

	mov ss, ax	; Set the Stack Segment Register to 0	

	; Stack Pointer
	; The Stack Pointer points to the top of the stack
	; The stack grows downwards, so put it at the start of the program

	mov sp, 0x7C00	; Stack Point to top of program

	; Perform a far jump to make sure that we are at Code Segment 0
	; Retf ( Return Far ) takes the Instruction Pointer and Code Segment Register from the stack
	; We need to push 0 ( for the code segment reg ) and the address to jump to

	push es			; Push 0 to the Stack
	push word main	; Push where we want to jump to ( main )
	retf			; Far jump which gets us to CS 0

main:
	mov si, BOOTING_MSG

	call print

	jmp hang


hang:
	jmp hang

BOOTING_MSG: db "BOOTING...", ENDL, 0

times 510-($-$$) db 0
dw 0xAA55

; BOOT PART 2

