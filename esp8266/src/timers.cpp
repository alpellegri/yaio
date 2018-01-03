#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include "fbconf.h"
#include "fblog.h"
#include "fbutils.h"
#include "timesrv.h"

static uint32_t t247_last = 0;

#define TestInRange(x, l, h) (((x) > (l)) && ((x) <= (h)))

void MonitorTimers(void) {
  uint8_t len = FB_getIoEntryLen();
  IoEntry_t *io_entry = FB_getIoEntry();
  // get time
  uint32_t current = getTime();
  uint32_t t247 = 60 * ((current / 3600) % 24) + (current / 60) % 60;
  // Serial.printf(">> t247 %d\n", t247);

  // loop over timers
  for (uint8_t i = 0; i < len; i++) {
    // test in range
    if (io_entry[i].type == kTimer) {
      // convert is to 24_7 time
      uint32_t _time = 60 * (io_entry[i].id >> 24) + (io_entry[i].id & 0xFF);
      bool res = TestInRange(_time, t247_last, t247);
      if (res == true) {
        // action
        Serial.printf_P(PSTR(">>> Action on timer %s at time %d\n"),
                        io_entry[i].name, t247);
        String log = F("Action on timer ");
        log += String(io_entry[i].name) + F("\n");
        fblog_log(log, false);
      }
    }
  }
  t247_last = t247;
}
