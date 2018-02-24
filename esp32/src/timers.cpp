#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include "fbconf.h"
#include "fblog.h"
#include "fbutils.h"
#include "timesrv.h"

#define DEBUG_PRINT(fmt, ...) Serial.printf_P(PSTR(fmt), ##__VA_ARGS__)

static uint32_t t24_last = 0;

void Timers_Service(void) {
  uint32_t current = getTime();
  uint32_t t24 = 60 * ((current / 3600) % 24) + (current / 60) % 60;
  uint8_t wday = getWeekDay();
  DEBUG_PRINT("%d, %d, %d\n", t24, t24_last, getWeekDay());

  if (t24 != t24_last) {
    t24_last = t24;

    uint8_t len = FB_getIoEntryLen();
    for (uint8_t i = 0; i < len; i++) {
      IoEntry entry = FB_getIoEntry(i);
      // test in range
      if (entry.code == kTimer) {
        // convert is to 24_7 time
        uint32_t v = atoi(entry.value.c_str());

        // minutes: bits 0...7
        // hours: bits 15...8
        // week day mask: bits 23...16
        uint32_t _time = 60 * ((v >> 8) & 0xFF) + (v & 0xFF);
        if (_time == t24) {
          // check week day
          uint8_t wday_mask = ((v >> 16) & 0xFF);
          if ((wday_mask & 0x80) == 0x00) {
            wday_mask = 0x7F;
          } else {
            wday_mask &= 0x7F;
          }
          if (((1 << wday) & wday_mask) != 0) {
            DEBUG_PRINT("Timers %s at time %d\n", entry.key.c_str(), t24);
            entry.ev = true;
          }
        }
      }
    }
  }
}
