#include "include/video.h"
#include "include/idt.h"
#include "include/io.h"
#include "include/int_func.h"
#include "include/drive_func.h"
#include "include/datatype.h"

#define BYTE unsigned char

int cursor = 0;

uint8_t buffer[512];

int init(){
	InitInterrupts();
	ClearScreen();

	return 0;
}

int main() {
	init();

	Print("Loading...\n", BLACKONWHITE, &cursor);

	ata_lba_read(0, 1, buffer);
	PrintBufferHex(buffer, 32, BLACKONWHITE, &cursor);
	
	PrintHexChar(buffer[0], BLACKONWHITE, &cursor);

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