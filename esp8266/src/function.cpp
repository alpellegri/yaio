#include <Arduino.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>

#include "fbconf.h"
#include "fbm.h"
#include "fbutils.h"
#include "rf.h"

static Ticker FunctionTimer;

String FunctionReqName;
static uint8_t FunctionReqPending;
static uint8_t FunctionReqIdx = 0xFF;

void ICACHE_RAM_ATTR FunctionSrv(void);

void Action(uint8_t src_idx, String action) {

  uint8_t idx = FB_getIoEntryIdx(action);
  IoEntry entry = FB_getIoEntry(idx);
  uint8_t port = entry.id >> 24;
  uint8_t value = entry.id & 0xFF;

  Serial.printf_P(PSTR("RF_Action: %d, %s\n"), idx, action.c_str());
  Serial.printf_P(PSTR("type: %d, name: %s, port: %d, value: %d\n"), entry.type,
                  entry.name.c_str(), port, value);
  switch (entry.type) {
  case kDOut: {
    // dout
    pinMode(port, OUTPUT);
    digitalWrite(port, !!value);
  } break;
  case kRadioOut:
    // rf
    RF_Send(entry.id, 24);
    break;
  case kLOut: {
    // lout
    FbmLogicReq(src_idx, port, !!value);
  } break;
  default:
    break;
  }
}

void FunctionReq(uint8_t src_idx, String key) {
  uint8_t idx = FB_getFunctionIdx(key);
  FunctionEntry entry = FB_getFunction(idx);
  if (idx != 0xFF) {
    FunctionReqName = String(key);
    FunctionReqIdx = idx;
    FunctionReqPending = 1;
    entry.src_idx = src_idx;
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
  FunctionEntry function = FB_getFunction(idx);
  Action(function.src_idx, function.action);
}

void ICACHE_RAM_ATTR FunctionSrv(void) {
  uint32_t curr_time;
  uint8_t i;

  curr_time = millis();

  // manage requests
  if (FunctionReqPending == 1) {
    FunctionEntry function = FB_getFunction(FunctionReqIdx);
    function.timer = curr_time;
    function.timer_run = 1;
    FunctionExec(FunctionReqIdx);
    FunctionRel();
  }

  uint8_t len = FB_getFunctionLen();
  // delay manager (many delayed action may be cuncurrent)
  for (i = 0; i < len; i++) {
    FunctionEntry function = FB_getFunction(i);
    // printf("delay manager @ id %d timer_run %d\n", i, Function.timer_run);
    if (function.timer_run == 1) {
      if ((curr_time - function.timer) >= function.delay) {
        function.timer_run = 0;
        FunctionTimer.detach();
        if (function.next.c_str()[0] != '\0') {
          FunctionReq(function.src_idx, function.next);
        }
      }
    }
  }
}
