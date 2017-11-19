#ifndef RF_H
#define RF_H

#include <Arduino.h>

extern void RF_deinitIoEntryDB(void);
extern void RF_deinitFunctionDB(void);
extern void RF_initIoEntryDB(uint8_t num);
extern void RF_initFunctionDB(uint8_t num);

extern void RF_addIoEntryDB(String key, uint8_t type, String id, String name,
                            String func);
extern char *RF_getRadioName(uint8_t idx);

extern void RF_addFunctionDB(String key, String type, String action,
                             uint32_t delay, String next);
extern uint8_t RF_checkRadioCodeDB(uint32_t code);
extern void RF_executeIoEntryDB(uint8_t idx);
extern uint8_t RF_checkRadioCodeTxDB(uint32_t code);

extern uint32_t RF_GetRadioCode(void);
extern void RF_Enable(void);
extern void RF_Disable(void);
extern void RF_ForceDisable(void);

extern void RF_Action(uint8_t src_idx, char *action);
extern void RF_MonitorTimers(void);

extern void RF_Loop(void);
extern bool RF_Task(void);

extern void RF_dumpIoEntry(void);

#endif
