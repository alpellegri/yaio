#include <Arduino.h>
#include <RCSwitch.h>

#include <stdio.h>
#include <string.h>

#include "fblog.h"
#include "rf.h"
#include "timesrv.h"

#define NUM_RADIO_CODE_RX_MAX 8
#define NUM_RADIO_CODE_TX_MAX 8
#define NUM_TIMER_MAX 8
#define NUM_DOUT_MAX 8

typedef struct {
  uint32_t id;
  uint8_t type;
  uint32_t action;
  uint32_t delay;
  uint32_t action_d;
  uint32_t stop_time;
  bool running;
  char name[23];
} RF_RadioCodeSts_t;

typedef struct {
  uint32_t time;
  uint32_t action;
  uint8_t type;
} Timer_t;

RCSwitch mySwitch = RCSwitch();
uint32_t RadioCode;
bool RF_StatusEnable = false;

// array 5 is used for delay timer running/idle
// array 6 is used for delay timer time stamp
RF_RadioCodeSts_t RadioCodes[NUM_RADIO_CODE_RX_MAX];
uint16_t RadioCodesLen = 0;
uint32_t RadioCodesTx[NUM_RADIO_CODE_TX_MAX];
uint16_t RadioCodesTxLen = 0;

Timer_t Timers[NUM_TIMER_MAX];
uint16_t TimersLen = 0;

uint8_t Dout[NUM_DOUT_MAX];
uint16_t DoutLen = 0;
uint32_t t247_last = 0;

void RF_ResetRadioCodeDB(void) { RadioCodesLen = 0; }
void RF_ResetRadioCodeTxDB(void) { RadioCodesTxLen = 0; }

void RF_ResetTimerDB(void) {
  uint32_t mytime = getTime();
  t247_last = 60 * ((mytime / 3600) % 24) + (mytime / 60) % 60;
  TimersLen = 0;
}

void RF_ResetDoutDB(void) { DoutLen = 0; }

void RF_AddRadioCodeDB(String id, String name, String type, String action,
                       String delay, String action_d) {
  if (RadioCodesLen < NUM_RADIO_CODE_RX_MAX) {
    RadioCodes[RadioCodesLen].id = atoi(id.c_str());
    strcpy(RadioCodes[RadioCodesLen].name, name.c_str());
    RadioCodes[RadioCodesLen].type = atoi(type.c_str());
    RadioCodes[RadioCodesLen].action = atoi(action.c_str());
    RadioCodes[RadioCodesLen].delay = atoi(delay.c_str());
    RadioCodes[RadioCodesLen].action_d = atoi(action_d.c_str());
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
      // manage start delay timers if any
      Serial.print(F("radio code delay: "));
      Serial.println(RadioCodes[i].delay);
      if (RadioCodes[i].delay != 0) {
        RadioCodes[i].running = true; // set timer running
        RadioCodes[i].stop_time =
            getTime() + RadioCodes[i].delay; // set timer time stamp
        // make an action
        RF_Action(RadioCodes[i].type, RadioCodes[i].action);
      } else {
        RF_Action(RadioCodes[i].type, RadioCodes[i].action);
      }
    }
    i++;
  }

  return idx;
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

uint32_t RF_GetRadioCode(void) {
  uint32_t Code;

  Code = RadioCode;
  RadioCode = 0;

  return Code;
}

bool RF_TestInRange(uint32_t t_test, uint32_t t_low, uint32_t t_high) {
  bool ret = false;
  // Serial.printf(">> %d, %d, %d\n", t_low, t_test, t_high);
  ret = (t_test >= t_low) && (t_test <= t_high);
  return ret;
}

void RF_Action(uint8_t type, uint32_t id) {
  Serial.print(F("RF_Action type "));
  Serial.println(type);
  if (type == 1) {
    // dout
    Serial.printf("DIO: %d, value %d\n", id >> 1, id & 0x01);
    pinMode(id >> 1, OUTPUT);
    digitalWrite(id >> 1, id & 0x01);
  } else if (type == 2) {
    // rf
    mySwitch.send(id, 24);
  }
}

void RF_MonitorTimers(void) {
  // get time
  uint32_t mytime = getTime();
  // Serial.printf(">> %d, %d, %d\n", (mytime/3600)%24, (mytime/60)%60,
  // (mytime)%60);
  uint32_t t247 = 60 * ((mytime / 3600) % 24) + (mytime / 60) % 60;
  // Serial.printf(">> t247 %d\n", t247);

  // loop delay timers
  for (uint8_t i = 0; i < RadioCodesLen; i++) {
    // check if running
    if (RadioCodes[i].running == true) {
      Serial.printf("radio code [%d] delay, time %d, stamp %d\n", i, mytime,
                    RadioCodes[i].stop_time);
      if (mytime >= RadioCodes[i].stop_time) {
        // perform an action
        RadioCodes[i].running = false; // set timer to idle
        RF_Action(RadioCodes[i].type, RadioCodes[i].action_d);
      }
    }
  }

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

      RF_Action(Timers[i].type, Timers[i].action);
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
    RadioCode = 0;
    Serial.println(F("RF Disable"));
    mySwitch.disableReceive();
  }
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
      if (RadioCode == 0) {
        Serial.print(F("radio code: "));
        Serial.println(value);
        RadioCode = value;
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
