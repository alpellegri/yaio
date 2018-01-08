#include <Arduino.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>

#include "fbconf.h"
#include "fbm.h"
#include "fbutils.h"
#include "rf.h"

static Ticker FunctionTimer;

static uint8_t FunctionReqPending;
static uint8_t FunctionReqIdx = 0xFF;

void ICACHE_RAM_ATTR FunctionSrv(void);

void ICACHE_RAM_ATTR Action(uint8_t src_idx, String &action) {

  uint8_t idx = FB_getIoEntryIdx(action);
  // Serial.printf("debug  Action %s, %d\n", action.c_str(), idx);
  if (idx != 0xFF) {
    IoEntry entry = FB_getIoEntry(idx);
    uint8_t port = entry.value >> 24;
    uint8_t value = entry.value & 0xFF;

    Serial.printf_P(PSTR("RF_Action: %d, %d, %s\n"), src_idx, idx,
                    action.c_str());
    Serial.printf_P(PSTR("type: %d, name: %s, port: %d, value: %d\n"),
                    entry.code, entry.name.c_str(), port, value);
    switch (entry.code) {
    case kPhyOut: {
      // dout
      pinMode(port, OUTPUT);
      digitalWrite(port, !!value);
    } break;
    case kRadioOut:
      // rf
      RF_Send(entry.value, 24);
      break;
    case kLogOut: {
      // lout
      FbmLogicReq(src_idx, port, !!value);
    } break;
    default:
      break;
    }
  } else {
    Serial.println("Action error\n");
  }
}

void ICACHE_RAM_ATTR FunctionReq(uint8_t src_idx, String key) {
  uint8_t idx = FB_getFunctionIdx(key);
  if (idx != 0xFF) {
    // Serial.printf("debug FunctionReq %s %d\n", key.c_str(), idx);
    FunctionEntry &entry = FB_getFunction(idx);
    noInterrupts();
    if (FunctionReqPending == 0) {
      // Serial.printf("debug FunctionReq set pending: %d\n", entry.src_idx);
      FunctionReqPending = 1;
      FunctionReqIdx = idx;
      entry.src_idx = src_idx;
      interrupts();
      FunctionTimer.attach_ms(100, FunctionSrv);
    } else {
      interrupts();
      // Serial.printf("debug FunctionReq is pending\n");
    }
  } else {
    // Serial.printf("debug FunctionReq error\n");
  }
}

void ICACHE_RAM_ATTR FunctionSrv(void) {
  uint32_t curr_time;
  uint8_t i;

  FunctionTimer.detach();
  curr_time = millis();

  // manage requests
  if (FunctionReqPending == 1) {
    FunctionEntry &function = FB_getFunction(FunctionReqIdx);
    function.timer = curr_time;
    function.timer_run = 1;
    // Serial.printf("debug call Action %d: %s\n", FunctionReqIdx, function.action.c_str());
    if (function.value.length() != 0) {
      Action(function.src_idx, function.value);
    }
    FunctionReqPending = 0;
    // Serial.printf("debug FunctionSrv release pending\n");
  } else {
  }

  bool need_arm = false;
  uint8_t len = FB_getFunctionLen();
  // delay manager (many delayed action may be cuncurrent)
  for (i = 0; i < len; i++) {
    FunctionEntry &function = FB_getFunction(i);
    // Serial.printf("delay manager @ id %d timer_run %d\n", i,
    //               function.timer_run);
    // Serial.printf("function.next.length %d\n", function.next.length());
    if (function.timer_run == 1) {
      if ((curr_time - function.timer) >= function.delay) {
        function.timer_run = 0;
        if (function.cb.length() != 0) {
          FunctionReq(function.src_idx, function.cb);
        }
      } else {
        need_arm = true;
      }
    }
  }

  if (need_arm == true) {
    FunctionTimer.attach_ms(100, FunctionSrv);
  } else {
    // FunctionTimer.detach();
  }
}
