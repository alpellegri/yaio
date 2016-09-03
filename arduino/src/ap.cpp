#include <Arduino.h>

#include <ESP8266WiFi.h>
#include <WiFiServer.h>

#include <WebSockets.h>
#include <WebSocketsClient.h>
#include <WebSocketsServer.h>
#include <Hash.h>

#include <stdio.h>
#include <string.h>

#include "ee.h"
#include "sta.h"

#define LED     D0 // Led in NodeMCU at pin GPIO16 (D0).
#define BUTTON  D3 // flash button at pin GPIO00 (D3)

// AP mode: local access
const char* ap_ssid     = "esp8266";
const char* ap_password = "123456789";

int cnt = 0;
bool enable_WiFi_Scan = false;
int ap_button = 0x55;

// create sebsocket server
WebSocketsServer webSocket = WebSocketsServer(81);

uint8_t port_id;
void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t lenght)
{
  uint16_t len;
  uint8_t sts;

  switch(type) {
    case WStype_DISCONNECTED:
      Serial.printf("[%u] Disconnected!\n", num);
      // STA_Setup();
      break;

    case WStype_CONNECTED: {
      IPAddress ip = webSocket.remoteIP(num);
      Serial.printf("[%u] Connected from %d.%d.%d.%d url: %s\n", num, ip[0], ip[1], ip[2], ip[3], payload);
      port_id = num;
      }
      break;

    case WStype_TEXT:
      Serial.printf("[%u] get Text: %s\n", num, payload);

      len = strlen((char*)payload);
      if (len != 0)
      {
        // save to epprom
        EE_StoreData((uint8_t*)payload, len);
      }
      break;

    case WStype_ERROR:
      Serial.printf("[%u] Error!\n", num);
      break;

    default:
      break;
    }
}

bool AP_Setup(void)
{
  bool ret = true;
  bool sts = false;

  digitalWrite(LED, false);

  // static ip for AP mode
  IPAddress ip(192,168,2,1);

  WiFi.disconnect();
  WiFi.softAPdisconnect(true);

  // enable_WiFi_Scan = EE_LoadData();

  port_id = 0xFF;
  Serial.printf("connecting mode AP\n");

  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  WiFi.mode(WIFI_AP_STA);

  WiFi.softAPConfig(ip, ip, IPAddress(255,255,255,0));
  WiFi.softAP(ap_ssid, ap_password);

  IPAddress myIP = WiFi.softAPIP();
  Serial.println("AP mode enabled");
  Serial.print("IP address: ");
  Serial.println(myIP);
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);

  return ret;
}

bool AP_Loop(void)
{
  int in;
  char c_str[25] = "";

  cnt++;

  in = digitalRead(BUTTON);
  if (in != ap_button)
  {
    ap_button = in;

    if (ap_button == true)
    {
      if (port_id != 0xFF)
      {
        Serial.printf(">");
        sprintf(c_str, "{\"sensor\":\"%06X\"}", cnt&0xFFFFFF);
        // "{\"sensor\":\"gps\",\"time\":1351824120,\"data\":[48.756080,2.302038]}";
        webSocket.sendTXT(port_id, c_str);
      }
    }
    Serial.printf("cnt: %08X, button %d\n", cnt, ap_button);
  }
  /* websocket only in mode 0 */
  webSocket.loop();
}

/* main function task */
bool AP_Task(void)
{
  bool ret = true;
  String str;

  if (enable_WiFi_Scan == true)
  {
    int n = WiFi.scanNetworks();
    Serial.println("scan done");
    if (n == 0)
    {
      Serial.println("no networks found");
    }
    else
    {
      char *sta_ssid = EE_GetSSID();

      for (int i = 0; i < n; ++i)
      {
        // Print SSID and RSSI for each network found
        // Serial.print(i + 1);
        // Serial.print(": ");
        // Serial.print(WiFi.SSID(i));
        // Serial.print(" (");
        // Serial.print(WiFi.RSSI(i));
        // Serial.print(")");
        // Serial.println((WiFi.encryptionType(i) == ENC_TYPE_NONE)?" ":"*");
        delay(10);
        // sta_ssid
        // const char *cstr = WiFi.SSID(i).c_str();
        // strcmp(sta_ssid, cstr);
        int test = WiFi.SSID(i).compareTo(String(sta_ssid));
        if (test == 0)
        {
          Serial.println(WiFi.SSID(i));
          // Serial.printf("network found: %s\n", WiFi.SSID(i));
          // ret = false;
        }
      }
    }
  }

  return ret;
}
