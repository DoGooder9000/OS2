SRC = src
BOOT = $(SRC)/boot
KERNEL = $(SRC)/kernel
BUILD = build

ASM = nasm

.PHONY: build run runfloppy

build: boot.bin

boot.bin: $(BUILD)/bootloader.bin $(BUILD)/kernel.bin
	cat $(BUILD)/bootloader.bin $(BUILD)/kernel.bin > $(BUILD)/boot.bin

$(BUILD)/bootloader.bin: $(BOOT)/stage1.asm $(BOOT)/stage2.asm
	mkdir -p $(BUILD)
	$(ASM) -f bin -o $(BUILD)/stage1.bin $(BOOT)/stage1.asm
	$(ASM) -f bin -o $(BUILD)/stage2.bin $(BOOT)/stage2.asm

	cat $(BUILD)/stage1.bin $(BUILD)/stage2.bin > $(BUILD)/bootloader.bin

$(BUILD)/kernel.bin: $(KERNEL)/kernel.asm
	mkdir -p $(BUILD)
	$(ASM) -f bin -o $(BUILD)/kernel.bin $(KERNEL)/kernel.asm

run: boot.bin
	qemu-system-i386 -drive format=raw,file=$(BUILD)/boot.bin -nographic

runfloppy: boot.bin
	qemu-system-i386 -fda $(BUILD)/boot.bin -nographic