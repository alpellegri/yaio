#include <Arduino.h>
#include <WebSocketsServer.h>
#include <WiFi.h>
#include <stdio.h>
#include <string.h>

#include "ee.h"
#include "sta.h"

#define LED 13
#define LED_OFF LOW
#define LED_ON HIGH

// AP mode: local access
static const char *ap_ssid = "uHome-node";
static const char *ap_password = "123456789";

static uint16_t ap_task_cnt;
static bool enable_WiFi_Scan = false;
static uint16_t ap_button = 0x55;

// create sebsocket server
static WebSocketsServer webSocket = WebSocketsServer(80);
static uint8_t port_id;

// #define PSTR(x) (x)
// #define printf_P printf

void webSocketEvent(uint8_t num, WStype_t type, uint8_t *payload,
                    size_t lenght) {
  uint16_t len;
  uint8_t sts;

  switch (type) {
  case WStype_DISCONNECTED:
    /* try to enable wifi scan when locally diconnected */
    enable_WiFi_Scan = EE_LoadData();
    Serial.print(F("["));
    Serial.print(num);
    Serial.print(F("]"));
    Serial.println(F(" Disconnected!"));
    ESP.restart();
    break;

  case WStype_CONNECTED: {
    /* disable wifi scan when locally connected */
    enable_WiFi_Scan = false;
    IPAddress ip = webSocket.remoteIP(num);
    Serial.printf_P(PSTR("[%u] Connected from %d.%d.%d.%d url: %s\n"), num,
                    ip[0], ip[1], ip[2], ip[3], payload);
    port_id = num;
  } break;

  case WStype_TEXT:
    len = strlen((char *)payload);
    Serial.printf_P(PSTR("[%u] get Text (%d): %s\n"), num, len, payload);

    if (len != 0) {
      // save to epprom
      EE_EraseData();
      EE_StoreData((uint8_t *)payload, len);
    }
    break;

  case WStype_ERROR:
    Serial.print(F("["));
    Serial.print(num);
    Serial.print(F(" Error!"));
    break;

  default:
    break;
  }
}

bool AP_Setup(void) {
  bool ret = true;
  bool sts = false;

  ap_task_cnt = 0;
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LED_ON);

  // static ip for AP mode
  IPAddress ip(192, 168, 2, 1);

  WiFi.disconnect();
  WiFi.softAPdisconnect(true);

  enable_WiFi_Scan = EE_LoadData();

  if (enable_WiFi_Scan == false) {
    port_id = 0xFF;
    Serial.println(F("Connecting mode AP"));

    WiFi.mode(WIFI_STA);
    WiFi.disconnect();
    delay(100);
    WiFi.mode(WIFI_AP_STA);

    WiFi.softAPConfig(ip, ip, IPAddress(255, 255, 255, 0));
    WiFi.softAP(ap_ssid, ap_password);

    IPAddress myIP = WiFi.softAPIP();
    Serial.println(F("AP mode enabled"));
    Serial.print(F("IP address: "));
    Serial.println(myIP);
    webSocket.begin();
    webSocket.onEvent(webSocketEvent);
  }

  return ret;
}

bool AP_Loop(void) {
// uint8_t in = digitalRead(BUTTON);

#if 0
  if (in != ap_button) {
    ap_button = in;
    if (in == false) {
      EE_EraseData();
      Serial.printf("EEPROM erased\n");
    }
  }
#endif

  /* websocket only in mode 0 */
  webSocket.loop();
}

/* main function task */
bool AP_Task(void) {
  bool ret = true;
  String str;

  if (enable_WiFi_Scan == true) {
    Serial.println(F("networks scan"));
    if (ap_task_cnt-- == 0) {
      ap_task_cnt = 10;
      int n = WiFi.scanNetworks();
      Serial.println(F("scan done"));
      if (n == 0) {
        Serial.println(F("no networks found"));
        ESP.restart();
      } else {
        String sta_ssid = EE_GetSSID();

        for (int i = 0; i < n; ++i) {
          yield();
          int test = WiFi.SSID(i).compareTo(sta_ssid);
          Serial.println(WiFi.SSID(i));
          if (test == 0) {
            Serial.print(F("network found: "));
            Serial.println(WiFi.SSID(i));
            ret = false;
            i = n; // exit for
          }
        }
      }
    }
  }

  return ret;
}
