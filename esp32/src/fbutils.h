#ifndef FBUTILS_H
#define FBUTILS_H

#include <Arduino.h>
#include <string>

#define NUM_IO_ENTRY_MAX 10
#define NUM_IO_FUNCTION_MAX 10

enum {
  kPhyIn = 0,
  kPhyOut,
  kLogIn,
  kLogOut,
  kRadioIn,
  kRadioOut,
  kRadioElem,
  kTimer,
  kBool,
  kInt,
  kFloat,
};

// template class std::basic_string<char>;

class IoEntry {
public:
  String key;
  String name;
  uint8_t code;
  uint32_t value;
  String cb;
  bool ev;
  bool wb;
};

class FunctionEntry {
public:
  String key; // firebase key
  String name;
  uint8_t code;
  String value;
  String cb;  // firebase key
};

extern void FB_deinitIoEntryDB(void);
extern void FB_deinitFunctionDB(void);
extern IoEntry &FB_getIoEntry(uint8_t i);
extern uint8_t FB_getIoEntryLen(void);
extern FunctionEntry &FB_getFunction(uint8_t i);
extern uint8_t FB_getFunctionLen(void);

extern void FB_addIoEntryDB(String key, String name, uint8_t code, String value,
                     String cb);
extern String &FB_getIoEntryNameById(uint8_t i);

extern void FB_addFunctionDB(String key, String name, uint8_t code, String value,
                     String cb);
extern uint8_t FB_checkRadioCodeDB(uint32_t code);
extern void FB_executeIoEntryDB(uint8_t idx);
extern uint8_t FB_checkRadioCodeTxDB(uint32_t code);

extern void FB_dumpIoEntry(void);
extern void FB_dumpFunctions(void);
extern uint8_t FB_getIoEntryIdx(String &key);
extern uint8_t FB_getFunctionIdx(String &key);

#endif
