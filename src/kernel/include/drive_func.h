#pragma once
#include "datatype.h"

void ata_lba_read(uint32_t lba, uint8_t sectors, void* buffer);
void ata_lba_write(uint32_t lba, uint8_t sectors, void* buffer);