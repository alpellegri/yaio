#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <WebSocketsServer.h>
#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "ee.h"
#include "sta.h"

#define LED D0 // Led in NodeMCU at pin GPIO16 (D0).
#define LED_OFF HIGH
#define LED_ON LOW
#define BUTTON D3 // flash button at pin GPIO00 (D3)

// AP mode: local access
static const char ap_ssid[] PROGMEM = "yaio-node";
static const char ap_password[] PROGMEM = "123456789";

static bool enable_WiFi_Scan = false;

// create sebsocket server
static WebSocketsServer *webSocket = NULL;
static uint8_t port_id;

void webSocketEvent(uint8_t num, WStype_t type, uint8_t *payload,
                    size_t lenght) {
  uint16_t len;

  switch (type) {
  case WStype_DISCONNECTED:
    ESP.restart();
    break;

  case WStype_CONNECTED: {
    /* disable wifi scan when locally connected */
    IPAddress ip = webSocket->remoteIP(num);
    DEBUG_PRINT("[%u] Connected from %d.%d.%d.%d url: %s\n", num, ip[0], ip[1],
                ip[2], ip[3], payload);
    port_id = num;
  } break;

  case WStype_TEXT:
    len = strlen((char *)payload);
    DEBUG_PRINT("[%u] get Text (%d): %s\n", num, len, payload);

    if (len != 0) {
      // save to epprom
      EE_EraseData();
      EE_StoreData((uint8_t *)payload, len);
    }
    break;

  case WStype_ERROR:
    DEBUG_PRINT("[%d] error!\n", num);
    break;

  default:
    break;
  }
}

bool AP_Setup(void) {
  bool ret = true;

  pinMode(LED, OUTPUT);
  digitalWrite(LED, LED_ON);

  enable_WiFi_Scan = EE_LoadData();

  if (enable_WiFi_Scan == false) {
    // static ip for AP mode
    IPAddress ip(192, 168, 2, 1);
    port_id = 0xFF;
    DEBUG_PRINT("Connecting mode AP\n");

    // AP Static IP
    if (!WiFi.softAP(String(FPSTR(ap_ssid)).c_str(),
                     String(FPSTR(ap_password)).c_str())) {
      Serial.println("AP Start Failed");
    }
    delay(100);
    if (!WiFi.softAPConfig(ip, ip, IPAddress(255, 255, 255, 0))) {
      Serial.println("AP Config Failed");
    }

    Serial.print("IP address: ");
    Serial.println(WiFi.softAPIP());

    DEBUG_PRINT("AP mode enabled\n");
    webSocket = new WebSocketsServer(80);
    webSocket->begin();
    webSocket->onEvent(webSocketEvent);
  }

  return ret;
}

bool AP_Loop(void) {
  /* websocket only in mode 0 */
  if (webSocket != NULL) {
    webSocket->loop();
  }
  return true;
}

/* main function task */
bool AP_Task(void) {
  bool ret = true;
  String str;

  if (enable_WiFi_Scan == true) {
    DEBUG_PRINT("networks scan\n");
    int n = WiFi.scanNetworks();
    DEBUG_PRINT("scan done\n");
    String sta_ssid = EE_GetSSID();

    for (int i = 0; i < n; ++i) {
      yield();
      int test = WiFi.SSID(i).compareTo(sta_ssid);
      Serial.println(WiFi.SSID(i));
      if (test == 0) {
        DEBUG_PRINT("network found: ");
        Serial.println(WiFi.SSID(i));
        ret = false;
        i = n; // exit for
      }
    }
    if (ret == true) {
      DEBUG_PRINT("no networks found: restart\n");
      ESP.restart();
    }
  }

  return ret;
}
