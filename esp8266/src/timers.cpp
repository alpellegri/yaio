#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include "fbconf.h"
#include "fblog.h"
#include "fbutils.h"
#include "timesrv.h"

#define DEBUG_VM(...) Serial.printf(__VA_ARGS__)

static uint32_t t247_last = 0;

void Timers_Service(void) {
  uint32_t current = getTime();
  uint32_t t247 = 60 * ((current / 3600) % 24) + (current / 60) % 60;
  uint8_t wday = getWeekDay();
  // Serial.printf_P(PSTR("%d, %d\n"), t247, getWeekDay());

  if (t247 != t247_last) {
    t247_last = t247;

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
        if (_time == t247) {
          // check week day
          uint8_t wday_mask = ((v >> 16) & 0xFF);
          if (((1 << wday) & wday_mask) != 0) {
            DEBUG_VM("Timers %s at time %d\n", entry.name.c_str(), t247);
            entry.ev = true;
          }
        }
      }
    }
  }
}
