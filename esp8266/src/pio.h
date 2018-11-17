#ifndef PIO_H
#define PIO_H

#include <Arduino.h>

extern void PIO_Set(uint8_t code, uint32_t ioctl);
extern void PIO_Service(void);

#endif
