#include "include/video.h"
#include "include/idt.h"
#include "include/io.h"
#include "include/int_func.h"
#include "include/drive_func.h"
#include "include/datatype.h"

#define BYTE unsigned char

int cursor = 0;

uint8_t buffer[512];
uint8_t* boot_ptr = (uint8_t*) 0x7C00;

int init(){
	InitInterrupts();
	ClearScreen();

	return 0;
}

int main() {
	init();

	Print("Loading...\n", BLACKONWHITE, &cursor);

	ata_lba_write(20, 1, boot_ptr);

	ata_lba_read(20, 1, buffer);
	PrintBufferHex(buffer, 512, 25, BLACKONWHITE, &cursor);

	char c;
	while (true){
		if (STDIN_ptr != 0){
			c = GetChar();

			if (c == 0x08) { // Backspace
				if (cursor != 0) {
					cursor--;
					PrintChar(' ', BLACKONBLACK, &cursor);
					cursor--;
				}
			}
			else {
				PrintChar(c, BLACKONWHITE, &cursor);
			}
		}
	}


	return 0;
}