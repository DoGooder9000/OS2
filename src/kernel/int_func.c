#include "include/int_func.h"
#include "include/io.h"

/* reinitialize the PIC controllers, giving them specified vector offsets
   rather than 8h and 70h, as configured by default */

#define ICW1_ICW4	0x01		/* Indicates that ICW4 will be present */
#define ICW1_SINGLE	0x02		/* Single (cascade) mode */
#define ICW1_INTERVAL4	0x04		/* Call address interval 4 (8) */
#define ICW1_LEVEL	0x08		/* Level triggered (edge) mode */
#define ICW1_INIT	0x10		/* Initialization - required! */

#define ICW4_8086	0x01		/* 8086/88 (MCS-80/85) mode */
#define ICW4_AUTO	0x02		/* Auto (normal) EOI */
#define ICW4_BUF_SLAVE	0x08		/* Buffered mode/slave */
#define ICW4_BUF_MASTER	0x0C		/* Buffered mode/master */
#define ICW4_SFNM	0x10		/* Special fully nested (not) */

#define CASCADE_IRQ 2

void PIC_Remap(int offset1, int offset2) {
	outb(PIC1_COMMAND, ICW1_INIT | ICW1_ICW4);  // starts the initialization sequence (in cascade mode)
	io_wait();
	outb(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);
	io_wait();
	outb(PIC1_DATA, offset1);                 // ICW2: Master PIC vector offset
	io_wait();
	outb(PIC2_DATA, offset2);                 // ICW2: Slave PIC vector offset
	io_wait();
	outb(PIC1_DATA, 1 << CASCADE_IRQ);        // ICW3: tell Master PIC that there is a slave PIC at IRQ2
	io_wait();
	outb(PIC2_DATA, CASCADE_IRQ);             // ICW3: tell Slave PIC its cascade identity
	io_wait();
	
	outb(PIC1_DATA, ICW4_8086);               // ICW4: have the PICs use 8086 mode (and not 8080 mode)
	io_wait();
	outb(PIC2_DATA, ICW4_8086);
	io_wait();

	// Unmask both PICs.
	outb(PIC1_DATA, 0);
	outb(PIC2_DATA, 0);
}

void Keyboard_Interrupt_C(uint8_t scancode){
	char c;

	/* Scancode set 2
	switch (scancode){
		case (0x1C): // A
		c = 'a';
		break;
		case (0x32): // B
		c = 'b';
		break;
		case (0x21): // C
			c = 'c';
			break;
		case (0x23): // D
			c = 'd';
			break;
		case (0x24): // E
			c = 'e';
			break;
		case (0x2B): // F
			c = 'f';
			break;
		case (0x34): // G
			c = 'g';
			break;
		case (0x33): // H
			c = 'h';
			break;
		case (0x43): // I
			c = 'i';
			break;
		case (0x3B): // J
			c = 'j';
			break;
		case (0x42): // K
			c = 'k';
			break;
		case (0x4B): // L
			c = 'l';
			break;
		case (0x3A): // M
			c = 'm';
			break;
		case (0x31): // N
			c = 'n';
			break;
		case (0x44): // O
			c = 'o';
			break;
		case (0x4D): // P
			c = 'p';
			break;
		case (0x15): // Q
			c = 'q';
			break;
		case (0x2D): // R
			c = 'r';
			break;
		case (0x1B): // S
			c = 's';
			break;
		case (0x2C): // T
			c = 't';
			break;
		case (0x3C): // U
			c = 'u';
			break;
		case (0x2A): // V
			c = 'v';
			break;
		case (0x1D): // W
			c = 'w';
			break;
		case (0x22): // X
			c = 'x';
			break;
		case (0x35): // Y
			c = 'y';
			break;
		case (0x1A): // Z
			c = 'z';
			break;

		default:
			c = 0;
			break;
	}
	*/

	switch (scancode) { // Scancode set 1. All other sets are automatically translated for backwards compatibility
		case 0x1E:
			c = 'a';
			break;
		case 0x30:
			c = 'b';
			break;
		case 0x2E:
			c = 'c';
			break;
		case 0x20:
			c = 'd';
			break;
		case 0x12:
			c = 'e';
			break;
		case 0x21:
			c = 'f';
			break;
		case 0x22:
			c = 'g';
			break;
		case 0x23:
			c = 'h';
			break;
		case 0x17:
			c = 'i';
			break;
		case 0x24:
			c = 'j';
			break;
		case 0x25:
			c = 'k';
			break;
		case 0x26:
			c = 'l';
			break;
		case 0x32:
			c = 'm';
			break;
		case 0x31:
			c = 'n';
			break;
		case 0x18:
			c = 'o';
			break;
		case 0x19:
			c = 'p';
			break;
		case 0x10:
			c = 'q';
			break;
		case 0x13:
			c = 'r';
			break;
		case 0x1F:
			c = 's';
			break;
		case 0x14:
			c = 't';
			break;
		case 0x16:
			c = 'u';
			break;
		case 0x2F:
			c = 'v';
			break;
		case 0x11:
			c = 'w';
			break;
		case 0x2D:
			c = 'x';
			break;
		case 0x15:
			c = 'y';
			break;
		case 0x2C:
			c = 'z';
			break;

		case 0x1C:
			c = '\n'; // 0x0A Linefeed
			break;
		case 0x0E:
			c = 0x8; // Backspace
			break;
		case 0x39:
			c = ' '; // Space
			break;

		default:
			c = 0;
			break;
	}

	if (c != 0 && STDIN_ptr < 256){
		STDIN[STDIN_ptr] = c;
		STDIN_ptr++;
	}

	return;
}