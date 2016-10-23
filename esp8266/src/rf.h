#ifndef RF_H
#define RF_H

#include <Arduino.h>

extern uint32_t RF_GetRadioCode(void);
extern bool RF_Setup(void);
extern void RF_Loop(void);
extern bool RF_Task(void);

#endif
