SRC = src
BOOT = $(SRC)/boot
KERNEL = $(SRC)/kernel
BUILD = build

ASM = nasm
CC = gcc
LD = ld

CC_FLAGS = -m32 -ffreestanding -fno-pie -fno-stack-protector
LD_FLAGS = -m elf_i386 --oformat binary

.PHONY: build run runfloppy clean

build: boot.bin

boot.bin: $(BUILD)/bootloader.bin $(BUILD)/kernel.bin
	cat $(BUILD)/bootloader.bin $(BUILD)/kernel.bin > $(BUILD)/boot.bin

$(BUILD)/bootloader.bin: $(BOOT)/stage1.asm $(BOOT)/stage2.asm
	mkdir -p $(BUILD)
	$(ASM) -f bin -o $(BUILD)/stage1.bin $(BOOT)/stage1.asm
	$(ASM) -f bin -o $(BUILD)/stage2.bin $(BOOT)/stage2.asm

	cat $(BUILD)/stage1.bin $(BUILD)/stage2.bin > $(BUILD)/bootloader.bin

#$(BUILD)/kernel.bin: $(KERNEL)/kernel.asm
#	mkdir -p $(BUILD)
#	$(ASM) -f bin -o $(BUILD)/kernel.bin $(KERNEL)/kernel.asm

$(BUILD)/kernel.bin: $(BUILD)/kernel_entry.o $(BUILD)/kernel.o $(KERNEL)/linker.ld
	mkdir -p $(BUILD)
	$(LD) $(LD_FLAGS) -T $(KERNEL)/linker.ld -o $(BUILD)/kernel.bin $(BUILD)/kernel_entry.o $(BUILD)/kernel.o

$(BUILD)/kernel_entry.o: $(KERNEL)/kernel_entry.asm
	$(ASM) -f elf32 -o $(BUILD)/kernel_entry.o $(KERNEL)/kernel_entry.asm

$(BUILD)/kernel.o: $(KERNEL)/kernel.c
	$(CC) $(CC_FLAGS) -c $(KERNEL)/kernel.c -o $(BUILD)/kernel.o

run: boot.bin
	qemu-system-i386 -drive format=raw,file=$(BUILD)/boot.bin -nographic

runfloppy: boot.bin
	qemu-system-i386 -fda $(BUILD)/boot.bin -nographic

clean:
	rm -rf build