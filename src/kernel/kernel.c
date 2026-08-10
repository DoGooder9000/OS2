#include "include/video.h"

#define BYTE unsigned char

int cursor = 0;

int main(){
	ClearScreen();

	Print("Hello!", BLACKONWHITE, &cursor);
	Print("Hello!", BLACKONWHITE, &cursor);

	return 0;
}