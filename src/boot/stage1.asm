BITS 16
ORG 0x7C00

%define ENDL 0x0D, 0x0A

jmp start

DRIVE_NUM: db 0

NUM_HEADS: dw 2
SEC_PER_TRCK: dw 18

STAGE2_SIZE: db 2
STAGE2_LBA_LOC: dw 1	; Addressing starts at 0 (boot sector)

STAGE2_SEGMENT 	equ 0x0000
STAGE2_OFFSET 	equ 0x0500

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

	mov [DRIVE_NUM], dl

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

	call ReadStage2

	; Pass some info for stage 2

	mov dl, [DRIVE_NUM]

	jmp STAGE2_SEGMENT:STAGE2_OFFSET

	jmp hang

; DISK FUNCTIONS

ReadStage2:
	pusha
	mov bx, STAGE2_SEGMENT
	mov es, bx
	mov bx, STAGE2_OFFSET

	mov ax, [STAGE2_LBA_LOC]	; Load LBA location in ax
	call LBAtoCHS				; Convert to CHS
	mov al, [STAGE2_SIZE]		; Move sectors to read into al
	mov dl, [DRIVE_NUM]			; Move drive number into dl

	call ReadSectorsFromDrive	; Read the sectors into memory

	popa

	ret

LBAtoCHS:
	; Parameters
	; AX - LBA

	; HPC - Heads per Cylinder ( Probably 2 )
	; SPT - Sectors per track ( Probably 18 )

	; Return
	; CX - Cylinder
	; DH - Head
	; DI - Sector

	; Cylinder 	= 	LBA / ( HPC * SPT )
	; Head		=	( LBA / SPT ) % HPT
	; Sector	=	( LBA % SPT ) + 1

	push bx				; Push BX to the Stack
	push si				; Push SI to the Stack

	mov si, ax			; Put the LBA into SI from AX
	mov ax, [NUM_HEADS]		; HPC
	mul word [SEC_PER_TRCK]	; SPT
	mov bx, ax	; BX = HPC * SPT
	mov ax, si
	xor dx, dx	; Set DX:AX to the LBA
	div bx
	push ax		; Push AX to the Stack to get the value later

	mov ax, si
	xor dx, dx		; Set DX:AX to LBA
	div word [SEC_PER_TRCK]	; ( LBA / SPT )
	xor dx, dx		; Set DX:AX to ( LBA / SPT )
	div word [NUM_HEADS]	; % HPC
	mov dh, dl		; Move it to DH
	push dx

	mov ax, si
	xor dx, dx		; Set DX:AX to LBA
	div word [SEC_PER_TRCK]	; % SPT
	inc dx
	mov di, dx

	pop dx				; Pop DX
	pop cx				; Pop CX

	pop si				; Pop SI off the Stack
	pop bx				; Pop BX off the Stack

	mov ax, cx	; Copy the Cylinder Value into AX from CX
	and cx, 0xFF	; AND CX with 255 ( This gets the low 8 bits )
	shl cx, 8	; Shift CX left by 8, into CH
	and ax, 0x300	; AND AX with 768 ( 0b 0000001100000000 ) ( This gets the high 2 bits )
	shr ax, 2	; Shift AX right by 2
	or cx, ax	; OR CX and AX
	or cx, di	; OR CX and DI to get the cylinder and sector together
	
	ret			; Return



ReadSectorsFromDrive:
	; Parameters
	;
	; Interrupt 0x13
	; AH 	- 0x02
	; AL 	- Sectors to Read Count
	; CH 	- Cylinder
	; CL 	- Sector
	; DH 	- Head
	; DL 	- Drive
	; ES:BX - Buffer Address Pointer

	; CX		= ---CH--- ---CL---
	; Cylinder	= 0000000 00
	; Sector	=           000000

	; Addressing of Buffer should guarantee that the complete buffer is inside the given segment
	; ( BX + size_of_buffer ) <= 0x10000

	; Start of calling the actual interrupt

	mov ah, 0x02	; Make sure 0x02 is in AH

	int 0x13	; Trigger the interrupt

	jc DiskError	; If the carry flag was set ( There was an Error ), jump to DiskError

	ret		; Return

DiskError:
	mov si, DISK_ERROR_MSG
	call print

	jmp hang

hang:
	jmp hang

BOOTING_MSG: db "BOOTING...", ENDL, 0
DISK_ERROR_MSG: db "DISK ERROR", ENDL, 0

times 510-($-$$) db 0
dw 0xAA55