#ifndef RF_H
#define RF_H

#include <Arduino.h>

extern void RF_SetRxPin(uint8_t pin);
extern void RF_SetTxPin(uint8_t pin);

extern void RF_Send(uint32_t data, uint8_t bits);

extern void RF_Setup(void);
extern void RF_Loop(void);
extern void RF_Service(void);

#endif
