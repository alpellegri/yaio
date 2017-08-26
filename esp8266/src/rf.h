#ifndef RF_H
#define RF_H

#include <Arduino.h>

extern void RF_ResetRadioCodeDB(void);
extern void RF_ResetRadioCodeTxDB(void);
extern void RF_ResetTimerDB(void);
extern void RF_ResetDoutDB(void);
extern void RF_ResetLoutDB(void);
extern void RF_ResetFunctionsDB(void);
extern void RF_AddRadioCodeDB(String id, String name, String func);
extern char *RF_GetRadioName(uint8_t idx);

extern void RF_AddRadioCodeTxDB(String string);
extern void RF_AddTimerDB(String type, String action, String hour,
                          String minute);
extern void RF_AddDoutDB(String action);
extern void RF_AddLoutDB(String action);
extern void RF_AddFunctionsDB(String name, String type, String action,
                              String delay, String next);
extern uint8_t RF_CheckRadioCodeDB(uint32_t code);
extern void RF_ExecuteRadioCodeDB(uint8_t idx);
extern uint8_t RF_CheckRadioCodeTxDB(uint32_t code);

extern uint32_t RF_GetRadioCode(void);
extern void RF_Enable(void);
extern void RF_Disable(void);
extern void RF_ForceDisable(void);

extern void RF_Action(uint8_t src_type, uint8_t src_idx, uint8_t type,
                      uint32_t id, char *name);
extern void RF_MonitorTimers(void);

extern void RF_Loop(void);
extern bool RF_Task(void);

#endif
