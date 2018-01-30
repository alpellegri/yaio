#include <string.h>
#include <time.h>

#include "timesrv.h"

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
    struct tm timeinfo;
    time_init = getLocalTime(&timeinfo, 0);
    if (time_init == false) {
      Serial.println(F("wait for NTP..."));
    } else {
      uint32_t current = getTime();
      Serial.print(F("UTC time: "));
      Serial.println(current);
    }
  }
  return time_init;
}
