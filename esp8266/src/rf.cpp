#include <Arduino.h>
#include <RCSwitch.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>

#include "cc1101.h"
#include "debug.h"
#include "fbconf.h"
#include "fblog.h"
#include "fbm.h"
#include "fbutils.h"
#include "rf.h"
#include "timesrv.h"

// #define USE_CC1101

// #define PORT_GDO0 ? // tx
// #define PORT_GDO2 13 (D7) // rx

static Ticker RFRcvTimer;

#ifdef USE_CC1101
static CC1101 rfHandle;
#else
static RCSwitch rfHandle = RCSwitch();
#endif

static uint32_t RadioCode;
static uint8_t RadioCodeLen;
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
      DEBUG_PRINT("%d / bit: %d - Protocol: %d\n", value,
                  rfHandle.getReceivedBitlength(),
                  rfHandle.getReceivedProtocol());
      if (RadioEv == false) {
        DEBUG_PRINT("radio code: %d\n", value);
        RadioEv = true;
        RadioCode = value;
        RadioCodeLen = rfHandle.getReceivedBitlength();
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

  DEBUG_PRINT("RF_CheckRadioCodeDB: code %d\n", radioid);
  while ((i < len) && (id == 0xFF)) {
    IoEntry entry = FB_getIoEntry(i);
    uint32_t v = entry.ioctl;
    if ((radioid == v) && (entry.code == kRadioIn)) {
      DEBUG_PRINT("radio code found in table %d\n", radioid);
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
    uint32_t RadioId = RadioCode;
    uint8_t data_bits = (RadioCodeLen > 24) ? (RadioCodeLen - 24) : (0);
    RadioId = RadioCode >> data_bits;

    uint8_t id = RF_checkRadioInCodeDB(RadioId);
    DEBUG_PRINT("RF_Service id %d\n", id);
    if (id != 0xFF) {
      IoEntry &entry = FB_getIoEntry(id);
      uint8_t value = RadioCode & ((1 << data_bits) - 1);
      entry.value = String(value);
      entry.ev = true;
      entry.ev_value = value;
      DEBUG_PRINT("RF_Service key=%s, value=%s\n", entry.key.c_str(),
                  entry.value.c_str());
    }
  }
}
