#include <Arduino.h>
#include <RCSwitch.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>

#include "fblog.h"
#include "fbm.h"
#include "rf.h"
#include "timesrv.h"

#define NUM_RADIO_CODE_RX_MAX 8
#define NUM_RADIO_CODE_TX_MAX 8
#define NUM_TIMER_MAX 4
#define NUM_DOUT_MAX 4
#define NUM_LOUT_MAX 4
#define NUM_FINCTION_MAX 5

typedef struct {
  uint32_t id;
  char name[25];
  char func[25];
} RF_RadioCodeSts_t;

typedef struct {
  uint32_t time;
  uint32_t action;
  uint8_t type;
} Timer_t;

typedef struct {
  char name[25];
  char next[25];
  uint8_t src_type;
  uint8_t src_idx;
  uint8_t type;
  uint8_t timer_run;
  uint32_t action;
  uint32_t delay;
  uint32_t timer;
} Function_t;

Ticker FunctionTimer;
Ticker RFRcvTimer;

RCSwitch mySwitch = RCSwitch();
uint32_t RadioCode;
bool RF_StatusEnable = false;

// array 5 is used for delay timer running/idle
// array 6 is used for delay timer time stamp
RF_RadioCodeSts_t RadioCodes[NUM_RADIO_CODE_RX_MAX];
uint8_t RadioCodesLen = 0;
uint32_t RadioCodesTx[NUM_RADIO_CODE_TX_MAX];
uint8_t RadioCodesTxLen = 0;
Timer_t Timers[NUM_TIMER_MAX];
uint8_t TimersLen = 0;
uint16_t Dout[NUM_DOUT_MAX];
uint8_t DoutLen = 0;
uint16_t Lout[NUM_LOUT_MAX];
uint8_t LoutLen = 0;
Function_t Function[NUM_FINCTION_MAX];
uint8_t FunctionLen = 0;

uint32_t t247_last = 0;

void RF_ResetRadioCodeDB(void) {
  RadioCodesLen = 0;
  RadioCode = 0;
}

void RF_ResetRadioCodeTxDB(void) {
  RadioCodesTxLen = 0;
  RadioCode = 0;
}

void RF_ResetTimerDB(void) {
  uint32_t mytime = getTime();
  t247_last = 60 * ((mytime / 3600) % 24) + (mytime / 60) % 60;
  TimersLen = 0;
}

void RF_ResetDoutDB(void) { DoutLen = 0; }
void RF_ResetLoutDB(void) { LoutLen = 0; }
void RF_ResetFunctionsDB(void) { FunctionLen = 0; }

void RF_AddRadioCodeDB(String id, String name, String func) {
  if (RadioCodesLen < NUM_RADIO_CODE_RX_MAX) {
    RadioCodes[RadioCodesLen].id = atoi(id.c_str());
    strcpy(RadioCodes[RadioCodesLen].name, name.c_str());
    strcpy(RadioCodes[RadioCodesLen].func, func.c_str());
    RadioCodesLen++;
  }
}

char *RF_GetRadioName(uint8_t idx) { return (RadioCodes[idx].name); }

void RF_AddRadioCodeTxDB(String string) {
  if (RadioCodesTxLen < NUM_RADIO_CODE_TX_MAX) {
    RadioCodesTx[RadioCodesTxLen] = atoi(string.c_str());
    RadioCodesTxLen++;
  }
}

void RF_AddTimerDB(String type, String action, String hour, String minute) {
  if (TimersLen < NUM_TIMER_MAX) {
    uint32_t evtime = 60 * atoi(hour.c_str()) + atoi(minute.c_str());
    Timers[TimersLen].time = evtime;
    Timers[TimersLen].type = atoi(type.c_str());
    Timers[TimersLen].action = atoi(action.c_str());
    TimersLen++;
  }
}

void RF_AddDoutDB(String action) {
  if (DoutLen < NUM_DOUT_MAX) {
    Dout[DoutLen] = atoi(action.c_str());
    DoutLen++;
  }
}

void RF_AddLoutDB(String action) {
  if (LoutLen < NUM_LOUT_MAX) {
    Lout[DoutLen] = atoi(action.c_str());
    LoutLen++;
  }
}

void RF_AddFunctionsDB(String name, String type, String action, String delay,
                       String next) {
  if (FunctionLen < NUM_FINCTION_MAX) {
    strcpy(Function[FunctionLen].name, name.c_str());
    Function[FunctionLen].type = atoi(type.c_str());
    Function[FunctionLen].action = atoi(action.c_str());
    Function[FunctionLen].delay = atoi(delay.c_str());
    strcpy(Function[FunctionLen].next, next.c_str());
    FunctionLen++;
  }
}

uint8_t FunctionGetIdx(char *name) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;
  uint8_t res;

  while ((i < FunctionLen) && (idx == 0xFF)) {
    res = strcmp(Function[i].name, name);
    if (res == 0) {
      idx = i;
    }
    i++;
  }

  return idx;
}

void FunctionSrv(void);
char FunctionReqName[25];
uint8_t FunctionReqPending;
uint8_t FunctionReqIdx = 0xFF;

void FunctionReq(uint8_t src_type, uint8_t src_idx, char *name) {
  uint8_t idx;

  idx = FunctionGetIdx(name);
  if (idx != 0xFF) {
    strcpy(FunctionReqName, name);
    FunctionReqIdx = idx;
    FunctionReqPending = 1;
    Function[idx].src_type = src_type;
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
  RF_Action(Function[idx].src_type, Function[idx].src_idx, Function[idx].type,
            Function[idx].action, NULL);
}

void FunctionSrv(void) {
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
          FunctionReq(Function[i].src_type, Function[i].src_idx,
                      Function[i].next);
        }
      }
    }
  }
}

uint8_t RF_CheckRadioCodeDB(uint32_t code) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;

  Serial.print(F("RF_CheckRadioCodeDB: code "));
  Serial.println(code);
  while ((i < RadioCodesLen) && (idx == 0xFF)) {
    Serial.print(F("radio table: "));
    Serial.println(RadioCodes[i].id);
    if (code == RadioCodes[i].id) {
      Serial.print(F("radio code found in table "));
      Serial.println(RadioCodes[i].id);
      idx = i;
    }
    i++;
  }

  return idx;
}

void RF_ExecuteRadioCodeDB(uint8_t idx) {
  // call
  FunctionReq(2, idx, RadioCodes[idx].func);
}

uint8_t RF_CheckRadioCodeTxDB(uint32_t code) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;

  Serial.print(F("RF_CheckRadioCodeTxDB: code "));
  Serial.println(code);
  while ((i < RadioCodesTxLen) && (idx == 0xFF)) {
    Serial.print(F("radio table: "));
    Serial.println(RadioCodesTx[i]);
    if (code == RadioCodesTx[i]) {
      Serial.print(F("radio Tx code found in table "));
      Serial.println(RadioCodesTx[i]);
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

void RF_Action(uint8_t src_type, uint8_t src_idx, uint8_t type, uint32_t action,
               char *name) {
  Serial.print(F("RF_Action type "));
  Serial.println(type);

  if (type == 1) {
    // dout
    uint8_t pin = action >> 1;
    uint8_t value = action & 0x00000001;
    pinMode(pin, OUTPUT);
    digitalWrite(pin, value);
  } else if (type == 2) {
    // rf
    mySwitch.send(action, 24);
  } else if (type == 3) {
    // lout
    uint8_t lin = action >> 1;
    uint8_t value = action & 0x00000001;
    /* logical actions req */
    FbmLogicReq(src_type, src_idx, lin, value);
  } else {
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
  for (uint8_t i = 0; i < TimersLen; i++) {
    // test in range
    uint32_t _time = Timers[i].time;
    bool res = RF_TestInRange(_time, t247_last, t247);
    if (res == true) {
      // action
      Serial.printf(">>> action on timer %d at time %d\n", i, t247);
      String log =
          "action on timer " + String(i) + " at time " + String(t247) + "\n";
      fblog_log(log, false);

      RF_Action(5, 0, Timers[i].type, Timers[i].action, NULL);
    }
  }
  t247_last = t247;
}

void RF_Enable(void) {
  if (RF_StatusEnable == false) {
    RF_StatusEnable = true;
    RadioCode = 0;
    Serial.println(F("RF Enable"));
    mySwitch.enableReceive(D7);
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

uint32_t RadioCodeLast;
uint32_t RF_GetRadioCode(void) {
  RadioCodeLast = RadioCode;
  RadioCode = 0;

  return RadioCodeLast;
}

// avoid receiving multiple code from same telegram
void RF_Unmask(void) {
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
        Serial.print(F("radio code: "));
        Serial.println(value);
        RadioCode = value;
        RFRcvTimer.attach(2.0, RF_Unmask);
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
