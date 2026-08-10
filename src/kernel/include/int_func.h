#pragma once
#include "datatype.h"

#define PIC1 0x20
#define PIC2 0xA0
#define PIC1_COMMAND	PIC1
#define PIC1_DATA	(PIC1+1)
#define PIC2_COMMAND	PIC2
#define PIC2_DATA	(PIC2+1)

#define PIC_EOI		0x20

#define PIC1_OFFSET 0x20
#define PIC2_OFFSET 0x28

void PIC_Remap(int offset1, int offset2);