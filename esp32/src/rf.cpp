#include <Arduino.h>
#include <RCSwitch.h>

#include <stdio.h>
#include <string.h>

#include "Ticker.h"

#include "cc1101.h"
#include "debug.h"
#include "fbconf.h"
#include "fblog.h"
#include "fbm.h"
#include "fbutils.h"
#include "rf.h"
#include "timesrv.h"

#define USE_CC1101
// CC1101 <===> ESP32
//   MOSI <---> MISO/19
//   MISO <---> MOSI/18
//    SCK <---> SCK/5
//     CS <---> A5/4
//    GD0 <---> 14/A6
//    GD2 <---> 15/A8
// #define PORT_GDO0 14 // tx
// #define PORT_GDO2 15 // rx

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

void RF_Send(uint32_t data, uint8_t bits) {
  DEBUG_PRINT("RF_Send %d, %d\n", data, bits);
  rfHandle.send(data, bits);
}

bool RF_GetRadioEv(void) {
  bool ev = RadioEv;
  if (RadioEv == true) {
    RadioEv = false;
  }
  return ev;
}

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

/* main function task */
void RF_Service(void) {
  uint32_t ev = RF_GetRadioEv();
  if (ev == true) {
    uint32_t RadioId = RadioCode;
    uint8_t data_bits = (RadioCodeLen > 24) ? (RadioCodeLen - 24) : (0);
    RadioId = RadioCode >> data_bits;

    for (uint8_t id = 0; id < FB_getIoEntryLen(); id++) {
      IoEntry &entry = FB_getIoEntry(id);
      if (entry.code == kRadioRx) {
        DEBUG_PRINT("RF_Service: %s, %d\n", entry.key.c_str(), RadioCode);
        entry.value = RadioCode;
        entry.ev = true;
        entry.ev_value = RadioCode;
        entry.wb = true;
      }

      if ((entry.code == kRadioIn) && (entry.ioctl == RadioId)) {
        uint8_t value = RadioCode & ((1 << data_bits) - 1);
        DEBUG_PRINT("RF_Service: %s, %d\n", entry.key.c_str(), RadioCode);
        entry.value = String(value);
        entry.ev = true;
        entry.ev_value = value;
        entry.wb = true;
      }
    }
  }
}
