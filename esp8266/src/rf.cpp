#include <Arduino.h>
#include <RCSwitch.h>

#include <stdio.h>
#include <string.h>

#include "rf.h"
#include "timesrv.h"
#include "fblog.h"

RCSwitch mySwitch = RCSwitch();
uint32_t RadioCode;
bool RF_StatusEnable = false;

uint32_t RadioCodes[10][5];
uint16_t RadioCodesLen = 0;
uint32_t RadioCodesTx[10];
uint16_t RadioCodesTxLen = 0;

uint32_t Timers[10][3];
uint16_t TimersLen = 0;

uint8_t Dout[10];
uint16_t DoutLen = 0;

void RF_ResetRadioCodeDB(void) { RadioCodesLen = 0; }
void RF_ResetRadioCodeTxDB(void) { RadioCodesTxLen = 0; }

uint32_t t247_last = 0;
void RF_ResetTimerDB(void) {
  time_t mytime = getTime();
  t247_last = 60*((mytime/3600)%24) + (mytime/60)%60;
  TimersLen = 0;
}

void RF_ResetDoutDB(void) { DoutLen = 0; }

void RF_AddRadioCodeDB(String id, String type, String action, String delay, String action_d) {
  RadioCodes[RadioCodesLen][0] = atoi(id.c_str());
  RadioCodes[RadioCodesLen][1] = atoi(type.c_str());
  RadioCodes[RadioCodesLen][2] = atoi(action.c_str());
  RadioCodes[RadioCodesLen][3] = atoi(delay.c_str());
  RadioCodes[RadioCodesLen][4] = atoi(action_d.c_str());
  RadioCodesLen++;
}

void RF_AddRadioCodeTxDB(String string) {
  RadioCodesTx[RadioCodesTxLen] = atoi(string.c_str());
  RadioCodesTxLen++;
}

void RF_AddTimerDB(String type, String action, String hour, String minute) {
  uint32_t evtime = 60*atoi(hour.c_str()) + atoi(minute.c_str());
  Timers[TimersLen][0] = evtime;
  Timers[TimersLen][1] = atoi(type.c_str());
  Timers[TimersLen][2] = atoi(action.c_str());
  TimersLen++;
}

void RF_AddDoutDB(String action) {
  Dout[DoutLen] = atoi(action.c_str());
  DoutLen++;
}

uint8_t RF_CheckRadioCodeDB(uint32_t code) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;

  Serial.printf("RF_CheckRadioCodeDB: code %x\n", code);
  while ((i < RadioCodesLen) && (idx == 0xFF)) {
    Serial.printf("radio table: %x, %x\n", code, RadioCodes[i]);
    if (code == RadioCodes[i][0]) {
      Serial.printf("radio code found in table\n");
      idx = i;
    }
    i++;
  }

  return idx;
}

uint8_t RF_CheckRadioCodeTxDB(uint32_t code) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;

  Serial.printf("RF_CheckRadioCodeTxDB: code %x\n", code);
  while ((i < RadioCodesTxLen) && (idx == 0xFF)) {
    Serial.printf("radio table: %x, %x\n", code, RadioCodesTx[i]);
    if (code == RadioCodesTx[i]) {
      Serial.printf("radio code found in table\n");
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
  Serial.printf(">> %d, %d, %d\n", t_low, t_test, t_high);
  ret = (t_test >= t_low) && (t_test <= t_high);
  return ret;
}

void RF_Action(uint8_t type, uint8_t idx) {
  Serial.printf("RF_Action type %d\n", type);
  if (type == 1) {
    // dout
    Serial.printf("DIO: %d, value %d\n", Dout[idx]>>1, Dout[idx]&0x01);
    digitalWrite(Dout[idx]>>1, Dout[idx]&0x01);
  } else if (type == 2) {
    // rf
  }
}

void RF_MonitorTimers(void) {
  // get time
  time_t mytime = getTime();
  // Serial.printf(">> %d, %d, %d\n", (mytime/3600)%24, (mytime/60)%60, (mytime)%60);
  uint32_t t247 = 60*((mytime/3600)%24) + (mytime/60)%60;
  // Serial.printf(">> t247 %d\n", t247);
  // loop over timers
  for (uint8_t i=0; i<TimersLen; i++) {
    // test in range
    uint32_t _time = Timers[i][0];
    bool res = RF_TestInRange(_time, t247_last, t247);
    if (res == true) {
      // action
      Serial.printf(">>>>>>>>>>>>>>>>>>>> action on timer %d at time %d\n", i, t247);
      String log = "action on timer " + String(i) + " at time " + String(t247) + "\n";
      fblog_log(log, false);
      RF_Action(1, i);
    }
  }
  t247_last = t247;
}

void RF_Enable(void) {
  if (RF_StatusEnable == false) {
    RF_StatusEnable = true;
    RadioCode = 0;
    Serial.printf("RF Enable\n");
    mySwitch.enableReceive(D7); // gpio13 D7
  }
}

void RF_Disable(void) {
  if (RF_StatusEnable == true) {
    RF_StatusEnable = false;
    RadioCode = 0;
    Serial.printf("RF disable\n");
    mySwitch.disableReceive(); // gpio13 D7
  }
}

void RF_Loop() {
  if (mySwitch.available()) {

    uint32_t value = (uint32_t)mySwitch.getReceivedValue();
    mySwitch.resetAvailable();

    if (value == 0) {
      Serial.print("Unknown encoding");
    } else {
      // Serial.printf(">>%x\n", value);
      // Serial.print(" / ");
      // Serial.print(mySwitch.getReceivedBitlength());
      // Serial.print("bit ");
      // Serial.print("Protocol: ");
      // Serial.println(mySwitch.getReceivedProtocol());
      if (RadioCode == 0) {
        Serial.printf("radio code: %x\n", value);
        RadioCode = value;
      } else {
        Serial.printf(".\n", value);
      }
    }
  }
}

/* main function task */
bool RF_Task(void) {
  bool ret = true;

  return ret;
}
