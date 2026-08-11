#pragma once
#include "datatype.h"

extern char STDIN[256];
extern uint8_t STDIN_ptr;

static inline void outb(uint16_t port, uint8_t value) {
    asm volatile (
        "out dx, al"
        :
        : "d"(port), "a"(value)
    );
}

static inline uint8_t inb(uint16_t port) {
    uint8_t value;

    asm volatile (
        "in al, dx"
        : "=a"(value)
        : "d"(port)
    );

    return value;
}

static inline void io_wait(void) {
    outb(0x80, 0);
}

char GetChar();

void KeyboardWaitToSendInput();

void KeyboardWaitToReadOutput();