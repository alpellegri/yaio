#include <Arduino.h>
#include <Ticker.h>
#include <RCSwitch.h>

#include <stdio.h>
#include <string.h>

#include "cc1101.h"
#include "fbconf.h"
#include "fblog.h"
#include "fbm.h"
#include "fbutils.h"
#include "rf.h"
#include "timesrv.h"

#define USE_CC1101

#define DEBUG_PRINT(fmt, ...) Serial.printf_P(PSTR(fmt), ##__VA_ARGS__)

// #define PORT_GDO0 14 // tx
// #define PORT_GDO2 15 // rx

static Ticker RFRcvTimer;

#ifdef USE_CC1101
static CC1101 rfHandle;
#else
static RCSwitch rfHandle = RCSwitch();
#endif

static uint32_t RadioCode;
static bool RadioEv;

void RF_SetRxPin(uint8_t pin) {
  DEBUG_PRINT("RF_SetRxPin %d\n", pin);
  rfHandle.enableReceive(pin);
#ifdef USE_CC1101
  rfHandle.strobe(CC1101_SIDLE);
  rfHandle.strobe(CC1101_SRX);
#endif
}

void RF_SetTxPin(uint8_t pin) {
  DEBUG_PRINT("RF_SetTxPin %d\n", pin);
  rfHandle.enableTransmit(pin);
}

void RF_Send(uint32_t data, uint8_t bits) { rfHandle.send(data, bits); }

bool RF_GetRadioEv(void) {
  bool ev = RadioEv;
  if (RadioEv == true) {
    RadioEv = false;
  }
  return ev;
}

uint32_t RF_GetRadioCode(void) { return RadioCode; }

// avoid receiving multiple code from same telegram
void ICACHE_RAM_ATTR RF_Unmask(void) { RFRcvTimer.detach(); }

void RF_Setup() {
#ifdef USE_CC1101
  rfHandle.setSoftCS(4);
  rfHandle.begin();
#endif
}

void RF_Loop() {
  if (rfHandle.available()) {

    noInterrupts();
    uint32_t value = rfHandle.getReceivedValue();
    rfHandle.resetAvailable();
    DEBUG_PRINT("getReceivedValue %d\n", value);
    interrupts();

    if (value == 0) {
      DEBUG_PRINT("Unknown encoding\n");
    } else {
      DEBUG_PRINT("%06X / bit: %d - Protocol: %d\n", value,
                  rfHandle.getReceivedBitlength(),
                  rfHandle.getReceivedProtocol());
      if (RadioEv == false) {
        DEBUG_PRINT("radio code: %06X\n", value);
        RadioEv = true;
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
  uint32_t ev = RF_GetRadioEv();
  if (ev == true) {
    uint8_t id = RF_checkRadioInCodeDB(RadioCode);
    DEBUG_PRINT("RF_Service %d\n", id);
    if (id != 0xFF) {
      IoEntryVec[id].ev = true;
      IoEntryVec[id].ev_value = RadioCode;
    }
  }
}
