#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "fbconf.h"
#include "fblog.h"
#include "fbutils.h"
#include "timesrv.h"

/* convert into second in a day */
#define conv2t24(x) ((x) % (3600 * 24))

static uint32_t t24_last = 0;

void Timers_Service(void) {
  uint32_t current = getTime();
  uint32_t t24 = conv2t24(current);
  uint8_t wday = getWeekDay();

  if (t24 != t24_last) {
    t24_last = t24;

    uint8_t len = FB_getIoEntryLen();
    for (uint8_t id = 0; id < len; id++) {
      IoEntry &entry = FB_getIoEntry(id);
      // test in range
      if (entry.code == kTimer) {
        uint32_t value = atoi(entry.value.c_str());
        uint32_t ioctl = entry.ioctl;
        // DEBUG_PRINT("Time %s: %d, %d, %d\n", entry.key.c_str(), t24, value,
        //             getWeekDay());
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
      } else if (entry.code == kTimeout) {
        uint32_t value = atoi(entry.value.c_str());
        uint32_t ioctl = entry.ioctl;
        // DEBUG_PRINT("Time %s: %d, %d, %d\n", entry.key.c_str(), t24, value,
        //             getWeekDay());
        // this is a timeout
        if ((value != 0) && (entry.ev_tmstamp != 0)) {
          // uint32_t ts = conv2t24(entry.ev_tmstamp);
          uint32_t delta = conv2t24(current - entry.ev_tmstamp);
          DEBUG_PRINT("Timeout active %s %d %d %d\n", entry.key.c_str(), t24,
                      conv2t24(entry.ev_tmstamp), delta);
          if (delta > value) {
            entry.value = String(0);
            entry.ev_tmstamp = 0;
            DEBUG_PRINT("Timeout %s at time %d\n", entry.key.c_str(), t24);
            entry.ev = true;
            entry.ev_value = (ioctl & (1 << 24)) != 0;
            entry.wb = true;
          }
        }
      } else {
      }
    }
  }
}
