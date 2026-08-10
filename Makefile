SRC := src
BOOT := $(SRC)/boot
KERNEL := $(SRC)/kernel
BUILD := build

ASM := nasm
CC := gcc
LD := ld

CC_FLAGS := -m32 -ffreestanding -fno-pie -fno-stack-protector
LD_FLAGS := -m elf_i386 --oformat binary

KERNEL_C_FILES := $(wildcard $(KERNEL)/*.c)
KERNEL_OBJS := $(patsubst $(KERNEL)/%.c, $(BUILD)/%.o, $(KERNEL_C_FILES))

.PHONY: build run runnographic clean

build: $(BUILD)/boot.bin

$(BUILD)/boot.bin: $(BUILD)/bootloader.bin $(BUILD)/kernel.bin
	cat $^ > $@

#----------------------------#

$(BUILD)/bootloader.bin: $(BUILD)/stage1.bin $(BUILD)/stage2.bin
	cat $^ > $@

$(BUILD)/stage1.bin: $(BOOT)/stage1.asm
	mkdir -p $(BUILD)
	$(ASM) -f bin -o $@ $<

$(BUILD)/stage2.bin: $(BOOT)/stage2.asm
	mkdir -p $(BUILD)
	$(ASM) -f bin -o $@ $<

#----------------------------#

$(BUILD)/kernel.bin: $(BUILD)/kernel_entry.o $(BUILD)/idt_asm.o $(KERNEL)/linker.ld $(KERNEL_OBJS)
	mkdir -p $(BUILD)
	$(LD) $(LD_FLAGS) -T $(KERNEL)/linker.ld -o $@ $(BUILD)/kernel_entry.o $(BUILD)/idt_asm.o $(KERNEL_OBJS)

$(BUILD)/kernel_entry.o: $(KERNEL)/kernel_entry.asm
	mkdir -p $(BUILD)
	$(ASM) -f elf32 -o $@ $<

$(BUILD)/idt_asm.o: $(KERNEL)/idt_asm.asm
	mkdir -p $(BUILD)
	$(ASM) -f elf32 -o $@ $<

#$(BUILD)/kernel.o: $(KERNEL_C_FILES)
#	$(CC) $(CC_FLAGS) -c $(KERNEL_C_FILES) -o $(BUILD)/kernel.o

$(BUILD)/%.o: $(KERNEL)/%.c
	mkdir -p $(BUILD)
	$(CC) $(CC_FLAGS) -c $< -o $@

runnographic: $(BUILD)/boot.bin
	qemu-system-i386 -drive format=raw,file=$(BUILD)/boot.bin -nographic

run: $(BUILD)/boot.bin
	qemu-system-i386 -drive format=raw,file=$(BUILD)/boot.bin

clean:
	rm -rf build

cleanrun:
	make clean
	wsl make build
	make run