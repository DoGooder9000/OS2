#include "include/video.h"
#include "include/idt.h"

#define BYTE unsigned char

int cursor = 0;

int init(){
	idt_init();
	ClearScreen();

	return 0;
}

int main(){
	init();

	Print("Loading...", BLACKONWHITE, &cursor);
	int a = 1 / 0;
	Print("Test", BLACKONWHITE, &cursor);

	return 0;
}