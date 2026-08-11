#include "include/video.h"
#include "include/idt.h"
#include "include/io.h"
#include "include/int_func.h"

#define BYTE unsigned char

int cursor = 0;

int init(){
	InitInterrupts();
	ClearScreen();

	return 0;
}

int main() {
	init();

	Print("Loading...\n", BLACKONWHITE, &cursor);

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