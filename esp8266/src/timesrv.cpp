#include <ESP8266HTTPClient.h>
#include <WiFiUdp.h>
#include <coredecls.h> // settimeofday_cb()
#include <string.h>
#include <time.h>

#include "debug.h"
#include "timesrv.h"

static bool time_init = false;

uint8_t getWeekDay(void) {
  time_t now = time(nullptr);
  return localtime(&now)->tm_wday;
}

uint32_t getTime(void) {
  time_t now = time(nullptr);
  return (uint32_t)now;
}

static void time_is_set(void) {
  uint32_t current = getTime();
  DEBUG_PRINT("UTC time: %d\n", current);
  time_init = true;
}

// void TimeSetup(void) { configTime(0, 0, "pool.ntp.org", "time.nist.gov"); }
static const char ntpserv1[] PROGMEM = "pool.ntp.org";
static const char ntpserv2[] PROGMEM = "time.nist.gov";
String srv1;
String srv2;
void TimeSetup(void) {
  srv1 = String(FPSTR(ntpserv1));
  srv2 = String(FPSTR(ntpserv2));
  settimeofday_cb(time_is_set);
  configTime(0, 0, srv1.c_str(), srv2.c_str());
}

bool TimeService(void) {
  if (time_init == false) {
    DEBUG_PRINT("wait for NTP...\n");
  } else {
#if 0
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
#endif
  }
  return time_init;
}
