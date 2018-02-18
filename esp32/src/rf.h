#ifndef RF_H
#define RF_H

#include <Arduino.h>

extern uint8_t RF_checkRadioCodeDB(uint32_t code);
extern void RF_executeIoEntryDB(uint8_t idx);
extern uint8_t RF_checkRadioCodeTxDB(uint32_t code);

extern uint32_t RF_GetRadioCode(void);
extern bool RF_GetRadioEv(void);

extern void RF_SetRxPin(uint8_t pin);
extern void RF_SetTxPin(uint8_t pin);

extern void RF_Send(uint32_t data, uint8_t bits);

extern void RF_Loop(void);
extern void RF_Service(void);

#endif
