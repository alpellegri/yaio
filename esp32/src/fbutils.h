#ifndef FBUTILS_H
#define FBUTILS_H

#include <Arduino.h>
#include <string>
#include <vector>

#define NUM_IO_ENTRY_MAX 20
#define NUM_IO_FUNCTION_MAX 20

enum {
  /*  0 */ kPhyIn = 0,
  /*  1 */ kPhyOut,
  /*  2 */ kLogIn,
  /*  3 */ kLogOut,
  /*  4 */ kRadioIn,
  /*  5 */ kRadioOut,
  /*  6 */ kRadioElem,
  /*  7 */ kTimer,
  /*  8 */ kBool,
  /*  9 */ kInt,
  /* 10 */ kFloat,
  /* 11 */ kRadioRx,
  /* 12 */ kMessaging,
};

// template class std::basic_string<char>;

class IoEntry {
public:
  uint8_t code;
  bool ev;
  bool wb;
  String key;
  String name;
  uint32_t value;
  String cb;
  uint32_t ev_value;
};

class FunctionEntry {
public:
  uint8_t code;
  String key; // firebase key
  String name;
  String value;
  String cb;  // firebase key
};

extern std::vector<IoEntry> IoEntryVec;
extern std::vector<FunctionEntry> FunctionVec;

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
extern uint8_t FB_getIoEntryIdx(const char *key);
extern uint8_t FB_getFunctionIdx(const char *key);

#endif
