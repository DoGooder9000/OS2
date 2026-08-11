#include "include/io.h"

char STDIN[256] = {0};
uint8_t STDIN_ptr = 0;

char GetChar(){
	STDIN_ptr--;
	return STDIN[STDIN_ptr];
}

void KeyboardWaitToSendInput(){
	while (inb(0x64) & 0x02);
}

void KeyboardWaitToReadOutput(){
	while (!(inb(0x64) & 0x01));
}