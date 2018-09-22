#include <string.h>
#include <time.h>
#include <HTTPClient.h>
#include <WiFiUdp.h>

#include "debug.h"
#include "timesrv.h"

static bool time_init = false;
static uint32_t last;

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
      DEBUG_PRINT("wait for NTP...\n");
    } else {
      uint32_t current = getTime();
      DEBUG_PRINT("UTC time: %d\n", current);
    }
  } else {
    uint32_t curr = millis();
    if ((curr - last) > 5000) {
      last = curr;
      IPAddress computer_ip(192, 168, 1, 1);
      WiFiUDP udp;
      const byte preamble[] = {0x00};

      // all NTP fields have been given values, now
      // you can send a packet requesting a timestamp:
      udp.beginPacket(computer_ip, 80); // NTP requests are to port 123
      udp.write(preamble, sizeof(preamble));
      udp.endPacket();
    }
  }
  return time_init;
}
