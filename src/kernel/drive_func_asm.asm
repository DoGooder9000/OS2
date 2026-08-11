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

	mov edx, 0x01F6		; Port to send drive and bit 24 - 27 of LBA
	shr eax, 24			; Get bit 24 - 27 in al
	and eax, 0x0F		; Makes sure its is only bits 24-27 set
	or al, 0xE0			; Set bit 6 in al for LBA mode & Master Drive
	out dx, al

	; Optional waste of cpu time to let drive correct itself
	;mov edx, 0x01F1
	;mov al, 0x00	; Null byte
	;out dx, al

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

	mov edx, 0x1F7
	in al, dx
	test al, 0x80
	jnz .ata_lba_read_ready

	test al, 0x08
	jz .ata_lba_read_ready

	; Start reading
	mov ecx, 256
	mov edx, 0x1F0
	rep insw
	dec bl

	jmp .ata_lba_read_ready

.ata_lba_read_done:
	popad
	popfd

	ret