#include "datatype.h"

#define IDT_MAX_DESCRIPTORS 256

typedef struct idt_entry_t {
	uint16_t    isr_low;		// The lower 16 bits of the ISR's address
	uint16_t    kernel_cs;		// The GDT segment selector that the CPU will load into CS before calling the ISR
	uint8_t     reserved;		// Set to zero
	uint8_t     attributes;		// Type and attributes; see the IDT page
	uint16_t    isr_high;		// The higher 16 bits of the ISR's address
}__attribute__((packed)) idt_entry_t;

typedef struct idtr_t{
	uint16_t	limit;	// Size
	uint32_t	base;	// Location
} __attribute__((packed)) idtr_t;

__attribute__((aligned(0x10))) 
static idt_entry_t idt[IDT_MAX_DESCRIPTORS];	// Define an array of idt entries

static idtr_t idtr;

void idt_set_descriptor(uint8_t vector, void* isr, uint8_t flags);
void exception_handler();
void idt_init(void);