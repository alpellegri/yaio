#include <Arduino.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>

#include "fbconf.h"
#include "fbm.h"
#include "fbutils.h"
#include "rf.h"

static Ticker FunctionTimer;

static char FunctionReqName[DBKEY_LEN];
static uint8_t FunctionReqPending;
static uint8_t FunctionReqIdx = 0xFF;

void ICACHE_RAM_ATTR FunctionSrv(void);

void Action(uint8_t src_idx, char *action) {

  IoEntry_t *io_entry = FB_getIoEntry();

  uint8_t idx = FB_getIoEntryIdx(action);
  uint8_t port = io_entry[idx].id >> 24;
  uint8_t value = io_entry[idx].id & 0xFF;

  Serial.printf_P(PSTR("RF_Action: %d, %s\n"), idx, action);
  Serial.printf_P(PSTR("type: %d, name: %s, port: %d, value: %d\n"),
                  io_entry[idx].type, io_entry[idx].name, port, value);
  switch (io_entry[idx].type) {
  case kDOut: {
    // dout
    pinMode(port, OUTPUT);
    digitalWrite(port, !!value);
  } break;
  case kRadioOut:
    // rf
    RF_Send(io_entry[idx].id, 24);
    break;
  case kLOut: {
    // lout
    FbmLogicReq(src_idx, port, !!value);
  } break;
  default:
    break;
  }
}

void FunctionReq(uint8_t src_idx, char *key) {
  uint8_t idx;

  FunctionEntry_t *function = FB_getFunction();

  idx = FB_getFunctionIdx(key);
  if (idx != 0xFF) {
    strcpy(FunctionReqName, key);
    FunctionReqIdx = idx;
    FunctionReqPending = 1;
    function[idx].src_idx = src_idx;
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
  FunctionEntry_t *function = FB_getFunction();
  Action(function[idx].src_idx, function[idx].action);
}

void ICACHE_RAM_ATTR FunctionSrv(void) {
  uint32_t curr_time;
  uint8_t i;

  curr_time = millis();
  FunctionEntry_t *function = FB_getFunction();
  uint8_t len = FB_getFunctionLen();

  // manage requests
  if (FunctionReqPending == 1) {
    function[FunctionReqIdx].timer = curr_time;
    function[FunctionReqIdx].timer_run = 1;
    FunctionExec(FunctionReqIdx);
    FunctionRel();
  }

  // delay manager (many delayed action may be cuncurrent)
  for (i = 0; i < len; i++) {
    // printf("delay manager @ id %d timer_run %d\n", i, Function[i].timer_run);
    if (function[i].timer_run == 1) {
      if ((curr_time - function[i].timer) >= function[i].delay) {
        function[i].timer_run = 0;
        FunctionTimer.detach();
        if (function[i].next[0] != '\0') {
          FunctionReq(function[i].src_idx, function[i].next);
        }
      }
    }
  }
}
