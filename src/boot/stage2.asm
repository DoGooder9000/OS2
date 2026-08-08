BITS 16
ORG 0x0500

%define ENDL 0x0D, 0x0A

jmp main

DRIVE_NUM: db 0x80

NUM_HEADS: dw 2
SEC_PER_TRCK: dw 18

print: ; Put the address of the line in SI
	push ax		; Store AX on the stack
	push si		; Store SI on the stack	

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

main:
	mov [DRIVE_NUM], dl

	mov si, STAGE_2_SUCCESS
	call print

	call ReadKernel

	jmp ProtectedModeEntry

	jmp hang

hang:
	jmp hang

ReadKernel:
	pusha
	mov bx, KERNEL_SEGMENT
	mov es, bx
	mov bx, KERNEL_OFFSET

	mov ax, KERNEL_LBA_LOC	; Load LBA location in ax
	call LBAtoCHS				; Convert to CHS
	mov al, KERNEL_SIZE		; Move sectors to read into al
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

; Protected mode stuff

ProtectedModeEntry:
	cli				; disable interrupts

	lgdt [GDT_DESC]		; load GDT register with start address of Global Descriptor Table

	; Enable the A20 Line
	call EnableA20

	mov eax, cr0 
	or eax, 1		; set PE ( Protection Enable ) bit in CR0 ( Control Register 0 )
	mov cr0, eax

	; Once PE bit is set, the CPU assumes segment selectors point to GDT descriptors, not real-mode segments.
	; Now we need to do a far jump
	jmp dword 0x8:(STAGE2_BASE+AfterProtectedModeJump)

EnableA20:
	in al, 0x92
	or al, 0b00000010
	out 0x92, al

	ret

; GDT

GDT:
	; Entries are 8 bytes long
	; First entry is always null
GDT_NULL:
	dq 0    ; The first entry is null
			; Define a quad word ( 8 bytes )

GDT_CODE_SEG_32:
	; Size
	dw 0xFFFF  ; Size / Limit ( max size at 4kb granularity )

	; Base
	dw 0        ; Low bits of the base / starting point
	db 0        ; High Byte of the base

	; Access Byte
	; Present Bit, DPL ( 2 Bits ), Descriptor Type, Executable Bit, Direction/Conforming Bit, Readable/Writable, Accessed Bit
	db 0b10011010
	
	; Flags plus the rest of the limit
	; Granularity Flag, Size Flag, Long-Mode Code Flag + the rest of the Limit
	db 0b1100_1111

	; Highest Byte of the Base
	db 0

GDT_DATA_SEG_32:
	; Size
	dw 0xFFFF  ; Size / Limit ( max size at 4kb granularity )

	; Base
	dw 0        ; Low bits of the base / starting point
	db 0        ; High Byte of the base

	; Access Byte
	; Present Bit, DPL ( 2 Bits ), Descriptor Type, Executable Bit, Direction/Conforming Bit, Readable/Writable, Accessed Bit
	db 0b10010010
	
	; Flags plus the rest of the limit
	; Granularity Flag, Size Flag, Long-Mode Code Flag + the rest of the Limit
	db 0b1100_1111

	; Highest Byte of the Base
	db 0

GDT_CODE_SEG_16:
	; Size
	dw 0xFFFF  ; Size / Limit ( max size at 4kb granularity )

	; Base
	dw 0        ; Low bits of the base / starting point
	db 0        ; High Byte of the base

	; Access Byte
	; Present Bit, DPL ( 2 Bits ), Descriptor Type, Executable Bit, Direction/Conforming Bit, Readable/Writable, Accessed Bit
	db 0b10011010
	
	; Flags plus the rest of the limit
	; Granularity Flag, Size Flag, Long-Mode Code Flag + the rest of the Limit
	db 0b0000_1111

	; Highest Byte of the Base
	db 0

GDT_DATA_SEG_16:
	; Size
	dw 0xFFFF  ; Size / Limit ( max size at 4kb granularity )

	; Base
	dw 0        ; Low bits of the base / starting point
	db 0        ; High Byte of the base

	; Access Byte
	; Present Bit, DPL ( 2 Bits ), Descriptor Type, Executable Bit, Direction/Conforming Bit, Readable/Writable, Accessed Bit
	db 0b10010010
	
	; Flags plus the rest of the limit
	; Granularity Flag, Size Flag, Long-Mode Code Flag + the rest of the Limit
	db 0b0000_1111

	; Highest Byte of the Base
	db 0

GDT_DESC:
	dw GDT_DESC - GDT - 1
	dd (GDT+STAGE2_BASE)

;

KERNEL_ADDRESS	equ 0x18000
KERNEL_SEGMENT	equ 0x1800
KERNEL_OFFSET	equ 0x0000
STAGE2_BASE		equ 0x0000

KERNEL_SIZE		equ 2
KERNEL_LBA_LOC	equ 3

STAGE_2_SUCCESS: db "STAGE 2 LOADED SUCCESSFULLY", ENDL, 0
DISK_ERROR_MSG: db "DISK ERROR", ENDL, 0

bits 32
AfterProtectedModeJump:
	; We can't turn on interrupts until we have an IDT

	; We need to set all the segment registers to their proper values
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	; The stack pointer is probably fine where it is

	; We need to load the Kernel now
	; Get FAT working? No more interrupts until an IDT
	jmp 0x8:KERNEL_ADDRESS

	jmp hang	; Shouldn't get here if Kernel Jump is Successful

times 1024 - ($-$$) db 0