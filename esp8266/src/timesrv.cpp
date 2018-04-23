#include <string.h>
#include <sys/time.h> // struct timeval
#include <time.h>

#include "timesrv.h"

#define DEBUG_PRINT(fmt, ...) Serial.printf_P(PSTR(fmt), ##__VA_ARGS__)

bool time_init = false;

uint8_t getWeekDay(void) {
  time_t now = time(nullptr);
  return localtime(&now)->tm_wday;
}

uint32_t getTime(void) {
  time_t now = time(nullptr);
  return (uint32_t)now;
}

void TimeSetup(void) { configTime(0, 0, "pool.ntp.org", "time.nist.gov"); }

bool TimeService(void) {
  if (time_init == false) {
    uint32_t current = getTime();
    if (current == 0) {
      DEBUG_PRINT("wait for NTP...\n");
    } else {
      time_init = true;
      DEBUG_PRINT("UTC time: %d\n", current);
    }
  }
  return time_init;
}
