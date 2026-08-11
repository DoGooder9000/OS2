#pragma once
#include "datatype.h"

#define VIDEO_MEMORY 0xB8000
#define CHAR_PER_LINE 80
#define LINES 25

#define BLACKONWHITE 0x0F
#define BLACKONBLACK 0x00

#define BYTE unsigned char

extern volatile BYTE* VidMemAddr;

void PrintChar(char c, BYTE color, int* cursor);
void Print(char* string, BYTE color, int* cursor);
void ClearScreen();
void PrintHexChar(uint8_t byte, uint8_t color, int* cursor);
void PrintBufferHex(uint8_t* buffer, int bytes, int width, uint8_t color, int* cursor);