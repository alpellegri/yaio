#ifndef FBUTILS_H
#define FBUTILS_H

#include <Arduino.h>

#define DBKEY_LEN 25

#define NUM_IO_ENTRY_MAX 10
#define NUM_IO_FUNCTION_MAX 10

typedef struct {
  uint32_t id;
  uint8_t type;
  char key[DBKEY_LEN];
  char name[25];
  char func[DBKEY_LEN];
} IoEntry_t;

typedef struct {
  char key[DBKEY_LEN];  // firebase key
  char next[DBKEY_LEN]; // firebase key
  uint8_t src_idx;
  uint8_t type;
  uint8_t timer_run;
  char action[DBKEY_LEN]; // firebase key
  uint32_t delay;
  uint32_t timer;
} FunctionEntry_t;

extern void FB_deinitIoEntryDB(void);
extern void FB_deinitFunctionDB(void);
extern uint8_t FB_getIoEntryLen(void);
extern IoEntry_t *FB_getIoEntry(void);
extern FunctionEntry_t *FB_getFunction(void);
extern uint8_t FB_getFunctionLen(void);

extern void FB_initIoEntryDB(uint8_t num);
extern void FB_initFunctionDB(uint8_t num);

extern void FB_addIoEntryDB(String key, uint8_t type, String id, String name,
                            String func);
extern char *FB_getIoEntryNameById(uint8_t idx);

extern void FB_addFunctionDB(String key, String type, String action,
                             uint32_t delay, String next);
extern uint8_t FB_checkRadioCodeDB(uint32_t code);
extern void FB_executeIoEntryDB(uint8_t idx);
extern uint8_t FB_checkRadioCodeTxDB(uint32_t code);

extern void FB_dumpIoEntry(void);
extern void FB_dumpFunctions(void);
extern uint8_t FB_getIoEntryIdx(char *key);
extern uint8_t FB_getFunctionIdx(char *key);


#endif
