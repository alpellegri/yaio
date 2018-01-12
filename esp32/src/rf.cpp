#include <Arduino.h>
#include <RCSwitch.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>

#include "fbconf.h"
#include "fblog.h"
#include "fbm.h"
#include "fbutils.h"
#include "function.h"
#include "rf.h"
#include "timesrv.h"

static Ticker RFRcvTimer;

static RCSwitch mySwitch = RCSwitch();
static uint32_t RadioCode;
static uint32_t RadioCodeLast;
static bool RF_StatusEnable = false;

uint8_t RF_checkRadioCodeDB(uint32_t code) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;

  uint8_t len = FB_getIoEntryLen();

  Serial.printf_P(PSTR("RF_CheckRadioCodeDB: code %06X\n"), code);
  while ((i < len) && (idx == 0xFF)) {
    IoEntry entry = FB_getIoEntry(i);
    if ((code == entry.value) && (entry.code == kRadioIn)) {
      Serial.printf_P(PSTR("radio code found in table %06X\n"), entry.value);
      idx = i;
    }
    i++;
  }

  return idx;
}

#if 0
void RF_executeIoEntryDB(uint8_t idx) {
  if (FB_getIoEntry(idx).cb.length() != 0) {
    FunctionReq(idx, FB_getIoEntry(idx).cb);
  }
}
#endif

#if 0
uint8_t RF_checkRadioCodeTxDB(uint32_t code) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;
  uint8_t len = FB_getIoEntryLen();

  Serial.print(F("RF_CheckRadioCodeTxDB: code "));
  Serial.println(code);
  while ((i < len) && (idx == 0xFF)) {
    IoEntry io_entry = FB_getIoEntry(i);
    Serial.print(F("radio table: "));
    Serial.println(io_entry.value);
    if ((code == io_entry.value) && (io_entry.code == kRadioOut)) {
      Serial.print(F("radio Tx code found in table "));
      Serial.println(io_entry.value);
      idx = i;
    }
    i++;
  }

  return idx;
}
#endif

void RF_Send(uint32_t data, uint8_t bits) { mySwitch.send(data, bits); }

void RF_Enable(void) {
  RF_StatusEnable = true;
  RadioCode = 0;
  RadioCodeLast = 0;
  Serial.println(F("RF Enable"));
  mySwitch.enableReceive(15);
}

void RF_Disable(void) {
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
        RFRcvTimer.attach_ms(1000, RF_Unmask);
      } else {
        Serial.println(F("."));
      }
    }
  }
}

/* main function task */
bool RF_Task(void) {
  bool ret = true;
  uint32_t code = RF_GetRadioCode();
  if (code != 0) {
    uint8_t id = RF_checkRadioCodeDB(code);
    if (id != 0xFF) {
      IoEntryVec[id].ev = true;
    }
  }
  return ret;
}
