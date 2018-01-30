#include <Arduino.h>
#include <RCSwitch.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>

#include "fbconf.h"
#include "fblog.h"
#include "fbm.h"
#include "fbutils.h"
#include "rf.h"
#include "timesrv.h"

#define RFRX 13 // D7

static Ticker RFRcvTimer;

static RCSwitch mySwitch = RCSwitch();
static uint32_t RadioCode;
static uint32_t RadioCodeLast;

void RF_Send(uint32_t data, uint8_t bits) { mySwitch.send(data, bits); }

void RF_Enable(void) {
  RadioCode = 0;
  RadioCodeLast = 0;
  Serial.println(F("RF Enable"));
  mySwitch.enableReceive(RFRX);
}

void RF_Disable(void) {
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

uint8_t RF_checkRadioInCodeDB(uint32_t radioid) {
  uint8_t i = 0;
  uint8_t id = 0xFF;

  uint8_t len = FB_getIoEntryLen();

  Serial.printf_P(PSTR("RF_CheckRadioCodeDB: code %06X\n"), radioid);
  while ((i < len) && (id == 0xFF)) {
    IoEntry entry = FB_getIoEntry(i);
    uint32_t v = atoi(entry.value.c_str());
    if ((radioid == v) && (entry.code == kRadioIn)) {
      Serial.printf_P(PSTR("radio code found in table %06X\n"),
                      entry.value.c_str());
      id = i;
    }
    i++;
  }

  return id;
}

/* main function task */
void RF_Service(void) {
  uint32_t radioid = RF_GetRadioCode();
  if (radioid != 0) {
    uint8_t id = RF_checkRadioInCodeDB(radioid);
    if (id != 0xFF) {
      IoEntryVec[id].ev = true;
      IoEntryVec[id].ev_value = radioid;
    } else {
      for (uint8_t i = 0; i < IoEntryVec.size(); i++) {
        if (IoEntryVec[i].code == kRadioRx) {
          IoEntryVec[i].value = radioid;
          IoEntryVec[i].ev = true;
          IoEntryVec[i].ev_value = radioid;
        }
      }
    }
  }
}
