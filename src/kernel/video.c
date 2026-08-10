#include "include/video.h"

volatile BYTE* VidMemAddr = (volatile BYTE*) VIDEO_MEMORY;

void PrintChar(char c, BYTE color, int* cursor){
	if (c == '\n'){
		*cursor += CHAR_PER_LINE;
		*cursor -= (*cursor) % CHAR_PER_LINE;
	}

	else {
		VidMemAddr[(*cursor)*2] = c;
		VidMemAddr[(*cursor)*2+1] = color;

		*cursor += 1;
	}
}

void Print(char* string, BYTE color, int* cursor){
	for (int i=0; string[i] != '\0'; i++){
		PrintChar(string[i], color, cursor);
	}
}

void ClearScreen(int* cursor){
	for(int i = 0; i < CHAR_PER_LINE * LINES * 2; i += 2){
		VidMemAddr[i] = ' '; // Set character to space
		VidMemAddr[i + 1] = BLACKONBLACK; // Set attribute byte
	}
	*cursor = 0;
}