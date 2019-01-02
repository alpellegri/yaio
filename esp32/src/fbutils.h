#ifndef FBUTILS_H
#define FBUTILS_H

#include <Arduino.h>
#include <cJSON.h>
#include <string>
#include <vector>

#define NUM_REGIDS_MAX 5
#define NUM_IO_ENTRY_MAX 40
#define NUM_IO_FUNCTION_MAX 40

enum {
  /*  0 */ kPhyDIn = 0,
  /*  1 */ kPhyDOut,
  /*  2 */ kDhtTemperature,
  /*  3 */ kDhtHumidity,
  /*  4 */ kRadioRx,
  /*  5 */ kRadioIn,
  /*  6 */ kRadioTx,
  /*  7 */ kTimer,
  /*  8 */ kBool,
  /*  9 */ kInt,
  /* 10 */ kFloat,
  /* 11 */ kMessaging,
  /* 12 */ kTimeout,
  /* 13 */ kPhyAIn,
  /* 14 */ kPhyAOut,
};

// template class std::basic_string<char>;

class IoEntry {
public:
  /* snapshot DB data */
  String key;
  uint8_t code;
  String value;
  uint32_t ioctl;
  String cb;
  bool enLog;
  bool enWrite;
  bool enRead;
  /* internal data */
  /* event notification flag */
  bool ev;
  /* event value */
  String ev_value;
  /* event timestamp */
  uint32_t ev_tmstamp;
  /* event timestamp */
  uint32_t ev_tmstamp_log;
  /* value write back request */
  uint8_t wb;
  /* log write back request */
  bool wblog;
};

class FuncEntry {
public:
  uint8_t code;
  String value;
};

class ProgEntry {
public:
  String key; // firebase key
  std::vector<FuncEntry> funcvec;
};

extern void FB_deinitRegIDsDB(void);
extern void FB_addRegIDsDB(String string);
extern std::vector<String> &FB_getRegIDs();

extern void FB_deinitIoEntryDB(void);
extern IoEntry &FB_getIoEntry(uint8_t i);
extern uint8_t FB_getIoEntryLen(void);
extern void FB_addIoEntryDB(String key, cJSON *obj);
extern String &FB_getIoEntryNameById(uint8_t i);
extern uint8_t FB_getIoEntryIdx(const char *key);

extern void FB_deinitProgDB(void);
extern void FB_addProgDB(String key, cJSON *obj);
extern uint8_t FB_getProgIdx(const char *key);
extern ProgEntry &FB_getProg(uint8_t i);
extern uint8_t FB_getFunctionIdx(const char *key);

extern void FB_dumpIoEntry(void);
extern void FB_dumpProg(void);

#endif
