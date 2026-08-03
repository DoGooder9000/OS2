SRC = src
BOOT = $(SRC)/boot
BUILD = build

ASM = nasm

.PHONY: build run

build: boot.bin

boot.bin: $(BOOT)/boot.asm
	mkdir -p $(BUILD)
	$(ASM) -f bin -o $(BUILD)/boot.bin $(BOOT)/boot.asm

run: boot.bin
	qemu-system-i386 -drive format=raw,file=$(BUILD)/boot.bin -nographic