bits 32

; ATA read sectors (LBA mode) 
;
; @param EAX Logical Block Address of sector
; @param CL  Number of sectors to read
; @param EDI The address of buffer to put data obtained from disk
;
; @return None
global ata_lba_read
ata_lba_read:
	xchg bx, bx
	mov eax, [esp + 4]    ; lba
	mov cl,  [esp + 8]    ; sectors
	mov edi, [esp + 12]    ; buffer

	call ata_lba_read_asm

	ret

ata_lba_read_asm:
	pushfd
	pushad

	mov ebx, eax

	call WaitReadyInit

	mov edx, 0x01F6		; Port to send drive and bit 24 - 27 of LBA
	shr eax, 24			; Get bit 24 - 27 in al
	and eax, 0x0F		; Makes sure its is only bits 24-27 set
	or al, 0xE0			; Set bit 6 in al for LBA mode & Master Drive
	out dx, al

	call Delay400

	; Send sector count
	mov edx, 0x1F2
	mov al, cl
	out dx, al

	mov edx, 0x1F3
	mov eax, ebx
	out dx, al		; Will only send low 8 bits

	mov edx, 0x1F4
	mov eax, ebx
	shr eax, 8
	out dx, al		; Will only send middle 8 bits

	mov edx, 0x1F5
	mov eax, ebx
	shr eax, 16
	out dx, al		; Will only send top 8 bits

	; Send read command
	mov edx, 0x1F7
	mov eax, 0x20
	out dx, al

	xor ebx, ebx
	mov bl, cl

.ata_lba_read_ready: ; Command and status registers are the same. DX already set
	test bl, bl
	jz .ata_lba_read_done

	call WaitReady

	; Start reading
	mov ecx, 256
	mov edx, 0x1F0
	rep insw
	dec bl

	; Delay to clear status registers
	;call Delay400

	jmp .ata_lba_read_ready

.ata_lba_read_done:
	popad
	popfd

	ret


; ATA write sectors (LBA mode) 
;
; @param EAX Logical Block Address of sector
; @param CL  Number of sectors to write
; @param EDI The address of buffer of data to put in disk
;
; @return None
global ata_lba_write
ata_lba_write:
	xchg bx, bx
	mov eax, [esp + 4]    ; lba
	mov cl,  [esp + 8]    ; sectors
	mov edi, [esp + 12]    ; buffer

	call ata_lba_write_asm

	ret

ata_lba_write_asm:
	pushfd
	pushad

	mov ebx, eax
	mov esi, edi

	call WaitReadyInit

	mov edx, 0x01F6		; Port to send drive and bit 24 - 27 of LBA
	shr eax, 24			; Get bit 24 - 27 in al
	and eax, 0x0F		; Makes sure its is only bits 24-27 set
	or al, 0xE0			; Set bit 6 in al for LBA mode & Master Drive
	out dx, al

	call Delay400

	; Send sector count
	mov edx, 0x1F2
	mov al, cl
	out dx, al

	mov edx, 0x1F3
	mov eax, ebx
	out dx, al		; Will only send low 8 bits

	mov edx, 0x1F4
	mov eax, ebx
	shr eax, 8
	out dx, al		; Will only send middle 8 bits

	mov edx, 0x1F5
	mov eax, ebx
	shr eax, 16
	out dx, al		; Will only send top 8 bits

	; Send write command
	mov edx, 0x1F7
	mov eax, 0x30
	out dx, al

	xor ebx, ebx
	mov bl, cl

.ata_lba_write_ready: ; Command and status registers are the same. DX already set
	test bl, bl
	jz .ata_lba_write_done

	call WaitReady

	; Start writing
	mov ecx, 256
	mov edx, 0x1F0
.ata_lba_write_loop:
	test ecx, ecx
	jz .ata_lba_write_loop_done
	outsw
	dec ecx
	jmp .ata_lba_write_loop

.ata_lba_write_loop_done:
	dec bl

	; Cache flush after each write command completes
	mov edx, 0x1F7
	mov eax, 0xE7
	out dx, al

	; Delay to clear status registers
	;call Delay400

	jmp .ata_lba_write_ready

.ata_lba_write_done:
	popad
	popfd

	ret

; Helper funcs

Delay400:
	pusha

	mov ecx, 16
	mov edx, 0x3F6
.Delay400Loop:
	test ecx, ecx
	jz .Delay400Done
	in al, dx
	dec ecx
	jmp .Delay400Loop

.Delay400Done:
	popa

	ret

WaitReady:
	pusha

	mov edx, 0x1F7

.WaitReadyLoop:
	in al, dx
	test al, 0x80				; BSY flag is cleared
	jnz .WaitReadyLoop

	test al, 0x08				; DRQ flag is set
	jz .WaitReadyLoop

	;mov edx, 0x1F1
	;in al, dx
	;xchg bx, bx

	;mov edx, 0x1F7
	;in al, dx

	; Check error flags
	test al, 0x01				; General Error flag
	jnz .WaitReadyLoop

	test al, 0x20				; Drive Error flag
	jnz .WaitReadyLoop

	popa

	ret

WaitReadyInit:
	pusha

	mov edx, 0x1F7

.WaitReadyInitLoop:
	in al, dx
	test al, 0x80				; BSY flag is cleared
	jnz .WaitReadyInitLoop

	test al, 0x08				; DRQ flag is cleared
	jnz .WaitReadyInitLoop

	popa

	ret