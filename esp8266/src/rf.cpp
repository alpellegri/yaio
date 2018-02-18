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

#define DEBUG_PRINT(fmt, ...) Serial.printf_P(PSTR(fmt), ##__VA_ARGS__)

static Ticker RFRcvTimer;

static RCSwitch mySwitchTx = RCSwitch();
static RCSwitch mySwitchRx = RCSwitch();
static uint32_t RadioCode;
static uint32_t RadioCodeLast;

void RF_SetRxPin(uint8_t pin) {
  DEBUG_PRINT("RF_SetRxPin %d\n", pin);
  mySwitchRx.enableReceive(pin);
}

void RF_SetTxPin(uint8_t pin) {
  DEBUG_PRINT("RF_SetTxPin %d\n", pin);
  mySwitchTx.enableTransmit(pin);
}

void RF_Send(uint32_t data, uint8_t bits) { mySwitchTx.send(data, bits); }

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
  if (mySwitchRx.available()) {

    noInterrupts();
    uint32_t value = (uint32_t)mySwitchRx.getReceivedValue();
    mySwitchRx.resetAvailable();
    interrupts();

    if (value == 0) {
      DEBUG_PRINT("Unknown encoding\n");
    } else {
      DEBUG_PRINT("%06X / bit: %d - Protocol: %d\n", value,
                  mySwitchRx.getReceivedBitlength(),
                  mySwitchRx.getReceivedProtocol());
      if (value != RadioCodeLast) {
        DEBUG_PRINT("radio code: %06X\n", value);
        RadioCode = value;
        RFRcvTimer.attach_ms(1000, RF_Unmask);
      } else {
        DEBUG_PRINT(".\n");
      }
    }
  }
}

uint8_t RF_checkRadioInCodeDB(uint32_t radioid) {
  uint8_t i = 0;
  uint8_t id = 0xFF;

  uint8_t len = FB_getIoEntryLen();

  DEBUG_PRINT("RF_CheckRadioCodeDB: code %06X\n", radioid);
  while ((i < len) && (id == 0xFF)) {
    IoEntry entry = FB_getIoEntry(i);
    uint32_t v = atoi(entry.value.c_str());
    if ((radioid == v) && (entry.code == kRadioMach)) {
      DEBUG_PRINT("radio code found in table %06X\n", radioid);
      id = i;
    }
    i++;
  }

  return id;
}

/* main function task */
void RF_Service(void) {
#if 0
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
#endif
}
