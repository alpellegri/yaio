#ifndef FBUTILS_H
#define FBUTILS_H

#include <Arduino.h>
#include <string>

#define NUM_IO_ENTRY_MAX 10
#define NUM_IO_FUNCTION_MAX 10

// template class std::basic_string<char>;

class IoEntry {
public:
  uint32_t value;
  uint8_t code;
  String key;
  String name;
  String cb;
};

class FunctionEntry {
public:
  String key;  // firebase key
  String cb; // firebase key
  uint8_t src_idx;
  uint8_t code;
  uint8_t timer_run;
  String value; // firebase key
  uint32_t delay;
  uint32_t timer;
};

extern void FB_deinitIoEntryDB(void);
extern void FB_deinitFunctionDB(void);
extern IoEntry& FB_getIoEntry(uint8_t i);
extern uint8_t FB_getIoEntryLen(void);
extern FunctionEntry& FB_getFunction(uint8_t i);
extern uint8_t FB_getFunctionLen(void);

extern void FB_addIoEntryDB(String key, uint8_t code, String value, String name,
                            String cb);
extern String& FB_getIoEntryNameById(uint8_t i);

extern void FB_addFunctionDB(String key, String code, String value,
                             uint32_t delay, String cb);
extern uint8_t FB_checkRadioCodeDB(uint32_t code);
extern void FB_executeIoEntryDB(uint8_t idx);
extern uint8_t FB_checkRadioCodeTxDB(uint32_t code);

extern void FB_dumpIoEntry(void);
extern void FB_dumpFunctions(void);
extern uint8_t FB_getIoEntryIdx(String& key);
extern uint8_t FB_getFunctionIdx(String& key);

#endif
