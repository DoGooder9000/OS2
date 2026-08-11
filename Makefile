SRC := src
BOOT := $(SRC)/boot
KERNEL := $(SRC)/kernel
BUILD := build

ASM := nasm
CC := gcc
LD := ld

CC_FLAGS := -m32 -masm=intel -ffreestanding -fno-pie -fno-stack-protector
LD_FLAGS := -m elf_i386 --oformat binary

KERNEL_C_FILES := $(wildcard $(KERNEL)/*.c)
KERNEL_OBJS := $(patsubst $(KERNEL)/%.c, $(BUILD)/%.o, $(KERNEL_C_FILES))

KERNEL_ASM_FILES := $(wildcard $(KERNEL)/*.asm)
KERNEL_ASM_OBJS := $(patsubst $(KERNEL)/%.asm, $(BUILD)/%.o, $(KERNEL_ASM_FILES))

$(info KERNEL ASM FILES: $(KERNEL_ASM_FILES))
$(info KERNEL ASM OBJS:  $(KERNEL_ASM_OBJS))
$(info KERNEL C OBJS:    $(KERNEL_OBJS))

.PHONY: build run runnographic clean

build: $(BUILD)/boot.bin

$(BUILD)/boot.bin: $(BUILD)/bootloader.bin $(BUILD)/kernel.bin
	cat $^ > $@
	truncate -s 1M $@

	ls -l build/bootloader.bin
	ls -l build/kernel.bin
	ls -l build/boot.bin

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

$(BUILD)/kernel.bin: $(KERNEL)/linker.ld $(KERNEL_ASM_OBJS) $(KERNEL_OBJS)
	mkdir -p $(BUILD)
	$(LD) $(LD_FLAGS) -T $(KERNEL)/linker.ld -o $@ $(KERNEL_ASM_OBJS) $(KERNEL_OBJS)

#$(BUILD)/kernel_entry.o: $(KERNEL)/kernel_entry.asm
#	mkdir -p $(BUILD)
#	$(ASM) -f elf32 -o $@ $<

#$(BUILD)/idt_asm.o: $(KERNEL)/idt_asm.asm
#	mkdir -p $(BUILD)
#	$(ASM) -f elf32 -o $@ $<

#$(BUILD)/int_func_asm.o: $(KERNEL)/int_func_asm.asm
#	mkdir -p $(BUILD)
#	$(ASM) -f elf32 -o $@ $<

#$(BUILD)/drive_func_asm.o: $(KERNEL)/drive_func_asm.asm
#	mkdir -p $(BUILD)
#	$(ASM) -f elf32 -o $@ $<

$(BUILD)/%.o: $(KERNEL)/%.asm
	mkdir -p $(BUILD)
	$(ASM) -f elf32 -o $@ $<

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