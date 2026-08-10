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

	Print("Loading...", BLACKONWHITE, &cursor);


	return 0;
}