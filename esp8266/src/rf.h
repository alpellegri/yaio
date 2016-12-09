#ifndef RF_H
#define RF_H

#include <Arduino.h>

extern void RF_ResetRadioCodeDB(void);
extern void RF_AddRadioCodeDB(String string);
extern bool RF_CheckRadioCodeDB(uint32_t code);

extern uint32_t RF_GetRadioCode(void);
extern void RF_Enable(void);
extern void RF_Disable(void);
extern void RF_Loop(void);
extern bool RF_Task(void);

#endif
