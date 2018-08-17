#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "fbconf.h"
#include "fblog.h"
#include "fbutils.h"
#include "timesrv.h"

static uint32_t t24_last = 0;

void Timers_Service(void) {
  uint32_t current = getTime();
  uint32_t t24 = 60 * ((current / 3600) % 24) + (current / 60) % 60;
  uint8_t wday = getWeekDay();
  // DEBUG_PRINT("%d, %d, %d\n", t24, t24_last, getWeekDay());

  if (t24 != t24_last) {
    t24_last = t24;

    uint8_t len = FB_getIoEntryLen();
    for (uint8_t id = 0; id < len; id++) {
      IoEntry &entry = FB_getIoEntry(id);
      // test in range
      if (entry.code == kTimer) {
        // convert is to 24_7 time
        uint32_t value = atoi(entry.value.c_str());
        uint32_t ioctl = entry.ioctl;

        // value: minutes in a day
        // week day mask: bits 23...16
        DEBUG_PRINT("%d, %d, %d\n", t24, value, getWeekDay());
        if (value == t24) {
          // check week day
          uint8_t wday_mask = ((ioctl >> 16) & 0xFF);
          if ((wday_mask & 0x80) != 0) {
            wday_mask = 0x7F;
          } else {
            wday_mask &= 0x7F;
          }
          DEBUG_PRINT("wday_mask %d\n", wday_mask);
          if (((1 << wday) & wday_mask) != 0) {
            DEBUG_PRINT("Timers %s at time %d\n", entry.key.c_str(), t24);
            // set event ev depending on polarity bit
            entry.ev = true;
            entry.ev_value = (ioctl & (1 << 24)) != 0;
            DEBUG_PRINT("entry: %d, %d\n", entry.ev, entry.ev_value);
          }
        }
      }
    }
  }
}
