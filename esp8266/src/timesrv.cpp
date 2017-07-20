#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <string.h>

#include "timesrv.h"

/* seconds */
#define NTP_UPDATE_INTERVAL (5 * 60)

static uint8_t timesrv_sm = 0;
static bool timesrv_run = false;
static uint16_t TimeServiceCnt;

static time_t ntp_time;
static time_t ntp_update_time;

/*-------- NTP code ----------*/

// NTP Servers:
// static const char ntpServerName[] = "us.pool.ntp.org";
static const char ntpServerName[] = "time.nist.gov";
// static const char ntpServerName[] = "time-a.timefreq.bldrdoc.gov";
// static const char ntpServerName[] = "time-b.timefreq.bldrdoc.gov";
// static const char ntpServerName[] = "time-c.timefreq.bldrdoc.gov";

// local port to listen for UDP packets
static uint16_t localPort = 8888;

// NTP time stamp is in the first 48 bytes of the message
static const uint16_t NTP_PACKET_SIZE = 48;

byte packetBuffer[NTP_PACKET_SIZE]; // buffer to hold incoming
// and outgoing packets
// A UDP instance to let us send and receive packets over UDP

WiFiUDP Udp;

// send an NTP request to the time server at the given address
static void sendNTPpacket(IPAddress &address) {
  // set all bytes in the buffer to 0
  memset(packetBuffer, 0, NTP_PACKET_SIZE);
  // Initialize values needed to form NTP request
  // (see URL above for details on the packets)
  packetBuffer[0] = 0b11100011; // LI, Version, Mode
  packetBuffer[1] = 0;          // Stratum, or type of clock
  packetBuffer[2] = 6;          // Polling Interval
  packetBuffer[3] = 0xEC;       // Peer Clock Precision
  // 8 bytes of zero for Root Delay & Root Dispersion
  packetBuffer[12] = 49;
  packetBuffer[13] = 0x4E;
  packetBuffer[14] = 49;
  packetBuffer[15] = 52;
  // all NTP fields have been given values, now
  // you can send a packet requesting a timestamp:
  Udp.beginPacket(address, 123); // NTP requests are to port 123
  Udp.write(packetBuffer, NTP_PACKET_SIZE);
  Udp.endPacket();
}

static void startNtpTime(void) {
  IPAddress ntpServerIP; // NTP server's ip address

  Udp.begin(localPort);

  while (Udp.parsePacket() > 0)
    ; // discard any previously received packets

  // get a random server from the pool
  WiFi.hostByName(ntpServerName, ntpServerIP);
  sendNTPpacket(ntpServerIP);
}

static void stopNtpTime(void) {
  /* stop udp client */
  Udp.stop();
}

static uint32_t getNtpTime(void) {
  uint32_t ret = 0;

  uint32_t size = Udp.parsePacket();

  if (size >= NTP_PACKET_SIZE) {
    Udp.read(packetBuffer, NTP_PACKET_SIZE); // read packet into the buffer
    uint32_t secsSince1900;
    // convert four bytes starting at location 40 to a long integer
    secsSince1900 = (unsigned long)packetBuffer[40] << 24;
    secsSince1900 |= (unsigned long)packetBuffer[41] << 16;
    secsSince1900 |= (unsigned long)packetBuffer[42] << 8;
    secsSince1900 |= (unsigned long)packetBuffer[43];
    ret = secsSince1900 - 2208988800UL;
  }

  return ret; // return 0 if unable to get the time
}

void time_set(uint32_t time) {
  ntp_update_time = millis();
  ntp_time = time;
}

time_t getTime(void) {
  time_t _time = (millis()-ntp_update_time)/1000 + ntp_time;

  return (_time);
}

bool TimeService(void) {
  switch (timesrv_sm) {
  case 0: {
    timesrv_sm = 1;
    timesrv_run = false;
    Serial.println("getNtpTime init done");
    TimeServiceCnt = -1;
  } break;
  case 1: {
    if (TimeServiceCnt < NTP_UPDATE_INTERVAL) {
      TimeServiceCnt++;
    } else {
      startNtpTime();
      timesrv_sm = 2;
    }
  } break;
  case 2: {
    Serial.println("getNtpTime");
    time_t mytime = getNtpTime();
    if (mytime != 0) {
      time_set(mytime);
      timesrv_run = true;
      TimeServiceCnt = 0;
    } else {
      /* retry: TimeServiceCnt not reset */
      Serial.println("getNtpTime fails");
    }
    stopNtpTime();
    timesrv_sm = 1;
  } break;
  }

  return timesrv_run;
}
