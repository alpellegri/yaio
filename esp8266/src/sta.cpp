#include <Arduino.h>

#include <ESP8266WiFi.h>
#include <FS.h>
#include <WiFiClient.h>

#include <stdio.h>
#include <string.h>

#include "ap.h"
#include "ee.h"
#include "fbm.h"
#include "fcm.h"
#include "fota.h"
#include "rf.h"
#include "timesrv.h"

#define LED D0    // Led in NodeMCU at pin GPIO16 (D0).
#define BUTTON D3 // flash button at pin GPIO00 (D3)

static uint8_t sta_button = 0x55;
static bool fota_mode = false;

bool STA_Setup(void) {
  bool ret = true;
  bool sts = false;
  int cnt;
  char *sta_ssid = NULL;
  char *sta_password = NULL;

  digitalWrite(LED, true);

  WiFi.disconnect();
  WiFi.softAPdisconnect(true);

  Serial.println(F("connecting mode STA"));
  Serial.println(F("Configuration parameters:"));
  sts = EE_LoadData();
  if (sts == true) {
    WiFi.mode(WIFI_STA);
    WiFi.disconnect();
    delay(100);
    WiFi.mode(WIFI_STA);

    sta_ssid = EE_GetSSID();
    sta_password = EE_GetPassword();
    Serial.print(F("sta_ssid: "));
    Serial.println(sta_ssid);
    Serial.print(F("sta_password: "));
    Serial.println(sta_password);
    Serial.println(F("trying to connect..."));
    WiFi.begin(sta_ssid, sta_password);
    cnt = 0;
    while ((WiFi.status() != WL_CONNECTED) && (cnt++ < 30)) {
      Serial.print(F("."));
      delay(500);
    }
    Serial.println();

    if (WiFi.status() == WL_CONNECTED) {
      Serial.print(F("connected: "));
      Serial.println(WiFi.localIP());

      SPIFFS.begin();
      File f = SPIFFS.open("/fota.req", "r+");
      if (!f) {
        fota_mode = false;
      } else {
        fota_mode = true;
        Serial.println("file open ");
        SPIFFS.remove("/fota.req");
        FOTA_UpdateReq();
      }

    } else {
      sts = false;
    }
  }

  if (sts != true) {
    Serial.println(F("not connected to router"));
    ret = false;
  }

  return ret;
}

void STA_FotaReq(void) {
  SPIFFS.open("/fota.req", "w");
  delay(5000);
  ESP.restart();
}

/* main function task */
bool STA_Task(void) {
  bool ret = true;

  if (WiFi.status() == WL_CONNECTED) {
    // wait for time service is up
    if (fota_mode == true) {
      bool res = FOTAService();
    } else {
      if (TimeService() == true) {
        RF_Task();
        yield();
        FbmService();
        yield();
        FcmService();
        yield();
      }
    }
  } else {
    Serial.println(F("WiFi.status != WL_CONNECTED"));
  }

  return ret;
}

void STA_Loop() {
  uint8_t in = digitalRead(BUTTON);

  if (in != sta_button) {
    sta_button = in;
    if (in == false) {
      // EE_EraseData();
      // Serial.printf("EEPROM erased\n");
    }
  }
}
