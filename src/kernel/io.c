#include "include/io.h"

void KeyboardWaitToSendInput(){
	while (inb(0x64) & 0x02);
}

void KeyboardWaitToReadOutput(){
	while (!(inb(0x64) & 0x01));
}