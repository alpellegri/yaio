#include <Arduino.h>
#include <Hash.h>
#include <WebSockets.h>
#include <WebSocketsClient.h>
#include <WebSocketsServer.h>
#include <WiFiServer.h>
#include <stdio.h>
#include <string.h>

#include "ee.h"
#include "rf.h"
#include "sta.h"

#define LED D0    // Led in NodeMCU at pin GPIO16 (D0).
#define BUTTON D3 // flash button at pin GPIO00 (D3)

// AP mode: local access
const char *ap_ssid = "esp8266";
const char *ap_password = "123456789";

uint16_t ap_task_cnt;
bool enable_WiFi_Scan = false;
uint16_t ap_button = 0x55;

// create sebsocket server
WebSocketsServer webSocket = WebSocketsServer(81);

uint8_t port_id;
void webSocketEvent(uint8_t num, WStype_t type, uint8_t *payload,
                    size_t lenght) {
  uint16_t len;
  uint8_t sts;

  switch (type) {
  case WStype_DISCONNECTED:
    /* try to enable wifi scan when locally diconnected */
    enable_WiFi_Scan = EE_LoadData();
    Serial.printf("[%u] Disconnected!\n", num);
    break;

  case WStype_CONNECTED: {
    /* disable wifi scan when locally connected */
    enable_WiFi_Scan = false;
    IPAddress ip = webSocket.remoteIP(num);
    Serial.printf("[%u] Connected from %d.%d.%d.%d url: %s\n", num, ip[0],
                  ip[1], ip[2], ip[3], payload);
    port_id = num;
  } break;

  case WStype_TEXT:
    Serial.printf("[%u] get Text: %s\n", num, payload);

    len = strlen((char *)payload);
    if (len != 0) {
      // save to epprom
      EE_StoreData((uint8_t *)payload, len);
    }
    break;

  case WStype_ERROR:
    Serial.printf("[%u] Error!\n", num);
    break;

  default:
    break;
  }
}

bool AP_Setup(void) {
  bool ret = true;
  bool sts = false;

  ap_task_cnt = 0;
  digitalWrite(LED, false);

  // static ip for AP mode
  IPAddress ip(192, 168, 2, 1);

  WiFi.disconnect();
  WiFi.softAPdisconnect(true);

  enable_WiFi_Scan = EE_LoadData();

  port_id = 0xFF;
  Serial.printf("connecting mode AP\n");

  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  WiFi.mode(WIFI_AP_STA);

  WiFi.softAPConfig(ip, ip, IPAddress(255, 255, 255, 0));
  WiFi.softAP(ap_ssid, ap_password);

  IPAddress myIP = WiFi.softAPIP();
  Serial.println("AP mode enabled");
  Serial.print("IP address: ");
  Serial.println(myIP);
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);

  return ret;
}

bool AP_Loop(void) {
  /* websocket only in mode 0 */
  webSocket.loop();
}

/* main function task */
bool AP_Task(void) {
  bool ret = true;
  String str;

  if (enable_WiFi_Scan == true) {
    if (ap_task_cnt-- == 0) {
      ap_task_cnt = 10;
      int n = WiFi.scanNetworks();
      Serial.println("scan done");
      if (n == 0) {
        Serial.println("no networks found");
      } else {
        char *sta_ssid = EE_GetSSID();

        for (int i = 0; i < n; ++i) {
          yield();
          int test = WiFi.SSID(i).compareTo(String(sta_ssid));
          if (test == 0) {
            Serial.print("network found: ");
            Serial.println(WiFi.SSID(i));
            ret = false;
          }
        }
      }
    }
  }

  return ret;
}
