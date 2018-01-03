#include <Arduino.h>
#include <RCSwitch.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>

#include "fbconf.h"
#include "fblog.h"
#include "fbm.h"
#include "rf.h"
#include "timesrv.h"

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

static Ticker FunctionTimer;
static Ticker RFRcvTimer;

static RCSwitch mySwitch = RCSwitch();
static uint32_t RadioCode;
static uint32_t RadioCodeLast;
static bool RF_StatusEnable = false;

static IoEntry_t *IoEntry = NULL;
static uint8_t IoEntryLen = 0;
static FunctionEntry_t *Function = NULL;
static uint8_t FunctionLen = 0;

static uint32_t t247_last = 0;

static char FunctionReqName[DBKEY_LEN];
static uint8_t FunctionReqPending;
static uint8_t FunctionReqIdx = 0xFF;

void ICACHE_RAM_ATTR FunctionSrv(void);

void RF_deinitIoEntryDB(void) {
  if (IoEntry != NULL) {
    free(IoEntry);
  }
  IoEntry = NULL;
  IoEntryLen = 0;
  RadioCode = 0; // hack
}

void RF_deinitFunctionDB(void) {
  if (Function != NULL) {
    free(Function);
  }
  Function = NULL;
  FunctionLen = 0;
}

void RF_initIoEntryDB(uint8_t num) {
  IoEntryLen = 0;
  RadioCode = 0; // hack
  if (num > 0) {
    IoEntry = (IoEntry_t *)malloc(num * sizeof(IoEntry_t));
  }
}

void RF_initFunctionDB(uint8_t num) {
  FunctionLen = 0;
  if (num > 0) {
    Function = (FunctionEntry_t *)malloc(num * sizeof(FunctionEntry_t));
  }
}

void RF_addIoEntryDB(String key, uint8_t type, String id, String name,
                     String func) {
  if (IoEntryLen < NUM_IO_ENTRY_MAX) {
    strcpy(IoEntry[IoEntryLen].key, key.c_str());
    IoEntry[IoEntryLen].id = atoi(id.c_str());
    IoEntry[IoEntryLen].type = type;
    strcpy(IoEntry[IoEntryLen].name, name.c_str());
    strcpy(IoEntry[IoEntryLen].func, func.c_str());
    IoEntryLen++;
  }
}

void RF_dumpIoEntry(void) {
  for (uint8_t i = 0; i < IoEntryLen; i++) {
    Serial.printf("%d: %06X, %d, %s, %s, %s\n", i, IoEntry[i].id,
                  IoEntry[i].type, IoEntry[i].key, IoEntry[i].name,
                  IoEntry[i].func);
  }
}

char *RF_getRadioName(uint8_t idx) { return (IoEntry[idx].name); }

void RF_addFunctionDB(String key, String type, String action, uint32_t delay,
                      String next) {
  if (FunctionLen < NUM_IO_FUNCTION_MAX) {
    strcpy(Function[FunctionLen].key, key.c_str());
    Function[FunctionLen].type = atoi(type.c_str());
    strcpy(Function[FunctionLen].action, action.c_str());
    Function[FunctionLen].delay = delay;
    strcpy(Function[FunctionLen].next, next.c_str());
    FunctionLen++;
  }
}

uint8_t getIoEntryIdx(char *key) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;
  uint8_t res;

  while ((i < IoEntryLen) && (idx == 0xFF)) {
    res = strcmp(IoEntry[i].key, key);
    if (res == 0) {
      idx = i;
    }
    i++;
  }

  return idx;
}

uint8_t getFunctionIdx(char *key) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;
  uint8_t res;

  while ((i < FunctionLen) && (idx == 0xFF)) {
    res = strcmp(Function[i].key, key);
    if (res == 0) {
      idx = i;
    }
    i++;
  }

  return idx;
}

void FunctionReq(uint8_t src_idx, char *key) {
  uint8_t idx;

  idx = getFunctionIdx(key);
  if (idx != 0xFF) {
    strcpy(FunctionReqName, key);
    FunctionReqIdx = idx;
    FunctionReqPending = 1;
    Function[idx].src_idx = src_idx;
    FunctionTimer.attach(0.1, FunctionSrv);
  } else {
  }
}

void FunctionRel(void) {
  FunctionReqName[0] = '\0';
  FunctionReqPending = 0;
  FunctionReqIdx = 0xFF;
}

void FunctionExec(uint8_t idx) {
  RF_Action(Function[idx].src_idx, Function[idx].action);
}

void ICACHE_RAM_ATTR FunctionSrv(void) {
  uint32_t curr_time;
  uint8_t i;

  curr_time = millis();

  // manage requests
  if (FunctionReqPending == 1) {
    Function[FunctionReqIdx].timer = curr_time;
    Function[FunctionReqIdx].timer_run = 1;
    FunctionExec(FunctionReqIdx);
    FunctionRel();
  }

  // delay manager (many delayed action may be cuncurrent)
  for (i = 0; i < FunctionLen; i++) {
    // printf("delay manager @ id %d timer_run %d\n", i, Function[i].timer_run);
    if (Function[i].timer_run == 1) {
      if ((curr_time - Function[i].timer) >= Function[i].delay) {
        Function[i].timer_run = 0;
        FunctionTimer.detach();
        if (Function[i].next[0] != '\0') {
          FunctionReq(Function[i].src_idx, Function[i].next);
        }
      }
    }
  }
}

uint8_t RF_checkRadioCodeDB(uint32_t code) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;

  Serial.printf_P(PSTR("RF_CheckRadioCodeDB: code %06X\n"), code);
  while ((i < IoEntryLen) && (idx == 0xFF)) {
    if ((code == IoEntry[i].id) && (IoEntry[i].type == kRadioIn)) {
      Serial.printf_P(PSTR("radio code found in table %06X\n"), IoEntry[i].id);
      idx = i;
    }
    i++;
  }

  return idx;
}

void RF_executeIoEntryDB(uint8_t idx) {
  // call
  FunctionReq(idx, IoEntry[idx].func);
}

uint8_t RF_checkRadioCodeTxDB(uint32_t code) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;

  Serial.print(F("RF_CheckRadioCodeTxDB: code "));
  Serial.println(code);
  while ((i < IoEntryLen) && (idx == 0xFF)) {
    Serial.print(F("radio table: "));
    Serial.println(IoEntry[i].id);
    if ((code == IoEntry[i].id) && (IoEntry[i].type == kRadioOut)) {
      Serial.print(F("radio Tx code found in table "));
      Serial.println(IoEntry[i].id);
      idx = i;
    }
    i++;
  }

  return idx;
}

bool RF_TestInRange(uint32_t t_test, uint32_t t_low, uint32_t t_high) {
  bool ret = false;
  // Serial.printf(">> %d, %d, %d\n", t_low, t_test, t_high);
  ret = (t_test >= t_low) && (t_test <= t_high);
  return ret;
}

void RF_Action(uint8_t src_idx, char *action) {

  uint8_t idx = getIoEntryIdx(action);
  uint8_t port = IoEntry[idx].id >> 24;
  uint8_t value = IoEntry[idx].id & 0xFF;

  Serial.printf_P(PSTR("RF_Action: %d, %s\n"), idx, action);
  Serial.printf_P(PSTR("type: %d, id: %08X, port: %d, value: %d\n"),
                  IoEntry[idx].type, IoEntry[idx].id, port, value);
  switch (IoEntry[idx].type) {
  case kDOut: {
    // dout
    pinMode(port, OUTPUT);
    digitalWrite(port, !!value);
  } break;
  case kRadioOut:
    // rf
    mySwitch.send(IoEntry[idx].id, 24);
    break;
  case kLOut: {
    // lout
    FbmLogicReq(src_idx, port, !!value);
  } break;
  default:
    break;
  }
}

void RF_MonitorTimers(void) {
  // get time
  uint32_t mytime = getTime();
  // Serial.printf(">> %d, %d, %d\n", (mytime/3600)%24, (mytime/60)%60,
  // (mytime)%60);
  uint32_t t247 = 60 * ((mytime / 3600) % 24) + (mytime / 60) % 60;
  // Serial.printf(">> t247 %d\n", t247);

  // loop over timers
  for (uint8_t i = 0; i < IoEntryLen; i++) {
    // test in range
    if (IoEntry[i].type == kTimer) {
      uint32_t _time = IoEntry[i].id;
      bool res = RF_TestInRange(_time, t247_last, t247);
      if (res == true) {
        // action
        Serial.printf_P(PSTR(">>> action on timer %d at time %d\n"), i, t247);
        String log =
            "action on timer " + String(i) + " at time " + String(t247) + "\n";
        fblog_log(log, false);

        // RF_Action(5, 0, IoEntry[i].action);
      }
    }
  }
  t247_last = t247;
}

void RF_Enable(void) {
  if (RF_StatusEnable == false) {
    RF_StatusEnable = true;
    RadioCode = 0;
    Serial.println(F("RF Enable"));
    mySwitch.enableReceive(15);
  }
}

void RF_Disable(void) {
  if (RF_StatusEnable == true) {
    RF_StatusEnable = false;
    Serial.println(F("RF Disable"));
    mySwitch.disableReceive();
  }
}

void RF_ForceDisable(void) {
  RF_StatusEnable = false;
  Serial.println(F("RF Disable"));
  mySwitch.disableReceive();
}

uint32_t RF_GetRadioCode(void) {
  RadioCodeLast = RadioCode;
  RadioCode = 0;

  return RadioCodeLast;
}

// avoid receiving multiple code from same telegram
void ICACHE_RAM_ATTR RF_Unmask(void) {
  RadioCodeLast = 0;
  RFRcvTimer.detach();
}

void RF_Loop() {
  if (mySwitch.available()) {

    noInterrupts();
    uint32_t value = (uint32_t)mySwitch.getReceivedValue();
    mySwitch.resetAvailable();
    interrupts();

    if (value == 0) {
      Serial.print(F("Unknown encoding"));
    } else {
      // Serial.printf(">>%x\n", value);
      // Serial.print(" / ");
      // Serial.print(mySwitch.getReceivedBitlength());
      // Serial.print("bit ");
      // Serial.print("Protocol: ");
      // Serial.println(mySwitch.getReceivedProtocol());
      if (value != RadioCodeLast) {
        Serial.printf_P(PSTR("radio code: %06X\n"), value);
        RadioCode = value;
        RFRcvTimer.attach(1.0, RF_Unmask);
      } else {
        Serial.println(F("."));
      }
    }
  }
}

/* main function task */
bool RF_Task(void) {
  bool ret = true;
  return ret;
}
