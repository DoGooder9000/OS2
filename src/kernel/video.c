#include "include/video.h"

volatile uint8_t* VidMemAddr = (volatile uint8_t*) VIDEO_MEMORY;

void PrintChar(char c, uint8_t color, int* cursor){
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

void Print(char* string, uint8_t color, int* cursor){
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

char DecimalToHex[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8',
						'9', 'A', 'B', 'C', 'D', 'E', 'F'};
void PrintHexChar(uint8_t byte, uint8_t color, int* cursor){
	PrintChar(DecimalToHex[byte>>4], color, cursor);
	PrintChar(DecimalToHex[byte&0xF], color, cursor);
}

void PrintBufferHex(uint8_t* buffer, int bytes, int width, uint8_t color, int* cursor){
	for (int i = 0; i < bytes; i++) {
		if (((i%width) == 0) && (i != 0)){
			PrintChar('\n', BLACKONWHITE, cursor);
		}
		PrintHexChar(buffer[i], color, cursor);
		PrintChar(' ', color, cursor);
	}
}