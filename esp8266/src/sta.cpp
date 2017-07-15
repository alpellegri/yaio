#include <Arduino.h>

#include <ESP8266WiFi.h>
#include <WiFiClient.h>

#include <stdio.h>
#include <string.h>

#include "ap.h"
#include "ee.h"
#include "fbm.h"
#include "fcm.h"
#include "timesrv.h"

#define LED D0    // Led in NodeMCU at pin GPIO16 (D0).
#define BUTTON D3 // flash button at pin GPIO00 (D3)

uint16_t sta_task_cnt;
uint8_t sta_button = 0x55;

bool STA_Setup(void) {
  bool ret = true;
  bool sts = false;
  int cnt;
  char *sta_ssid = NULL;
  char *sta_password = NULL;

  digitalWrite(LED, true);
  sta_task_cnt = 0;

  WiFi.disconnect();
  WiFi.softAPdisconnect(true);

  Serial.printf("connecting mode STA\n");
  Serial.printf("Configuration parameters:\n");
  sts = EE_LoadData();
  if (sts == true) {
    WiFi.mode(WIFI_STA);
    WiFi.disconnect();
    delay(100);
    WiFi.mode(WIFI_STA);

    sta_ssid = EE_GetSSID();
    sta_password = EE_GetPassword();
    Serial.printf("sta_ssid: %s\n", sta_ssid);
    Serial.printf("sta_password: %s\n", sta_password);
    Serial.printf("\ntrying to connect...\n");
    WiFi.begin(sta_ssid, sta_password);
    cnt = 0;
    while ((WiFi.status() != WL_CONNECTED) && (cnt++ < 30)) {
      Serial.print(".");
      delay(500);
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.println();
      Serial.print("connected: ");
      Serial.println(WiFi.localIP());
    } else {
      sts = false;
    }
  }

  if (sts != true) {
    Serial.println();
    Serial.println("not connected to router");
    ret = false;
  }

  return ret;
}

void STA_Loop() {
  uint8_t in = digitalRead(BUTTON);

#if 0
  if (in != sta_button) {
    sta_button = in;
    if (in == false) {
      EE_EraseData();
      Serial.printf("EEPROM erased\n");
    }
  }
#endif
}

/* main function task */
bool STA_Task(void) {
  bool ret = true;

  sta_task_cnt++;
  Serial.printf("task_cnt: %d, HEAP: %d\n", sta_task_cnt, ESP.getFreeHeap());

  if (WiFi.status() == WL_CONNECTED) {
    // wait for time service is up
    if (TimeService() == true) {
      yield();
      FbmService();
      yield();
      FcmService();
      yield();
    }
  } else {
    Serial.print("WiFi.status != WL_CONNECTED\n");
  }

  return ret;
}
