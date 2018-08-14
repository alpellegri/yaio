#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <FS.h>

#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "ee.h"
#include "fbm.h"
#include "fota.h"
#include "rf.h"
#include "timesrv.h"
#include "vm.h"

#define LED D0 // Led in NodeMCU at pin GPIO16 (D0).
#define LED_OFF HIGH
#define LED_ON LOW
#define BUTTON D3 // flash button at pin GPIO00 (D3)

static bool fota_mode = false;

bool STA_Setup(void) {
  bool ret = true;
  bool sts = true;
  int cnt;

  digitalWrite(LED, LED_OFF);

  WiFi.disconnect();
  WiFi.softAPdisconnect(true);

  DEBUG_PRINT("Connecting mode STA\n");
  DEBUG_PRINT("Configuration parameters:\n");

  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  WiFi.mode(WIFI_STA);

  String sta_ssid = EE_GetSSID();
  String sta_password = EE_GetPassword();
  DEBUG_PRINT("sta_ssid: %s\n", sta_ssid.c_str());
  DEBUG_PRINT("sta_password: %s\n", sta_password.c_str());
  DEBUG_PRINT("trying to connect...\n");

  WiFi.begin(sta_ssid.c_str(), sta_password.c_str());
  cnt = 0;
  while ((WiFi.status() != WL_CONNECTED) && (cnt++ < 30)) {
    DEBUG_PRINT(".");
    delay(500);
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    TimeSetup();
    RF_Setup();

    DEBUG_PRINT("connected: ");
    Serial.println(WiFi.localIP());

    SPIFFS.begin();
    File f = SPIFFS.open(String(FPSTR("/fota.req")).c_str(),
                         String(FPSTR("r+")).c_str());
    if (!f) {
      fota_mode = false;
    } else {
      fota_mode = true;
      DEBUG_PRINT("file open\n");
      SPIFFS.remove(String(FPSTR("/fota.req")).c_str());
      FOTA_UpdateReq();
    }
  } else {
    sts = false;
  }

  if (sts != true) {
    DEBUG_PRINT("not connected to router\n");
    ESP.restart();
    ret = false;
  }

  return ret;
}

void STA_FotaReq(void) {
  SPIFFS.open(String(FPSTR("/fota.req")).c_str(), String(FPSTR("w")).c_str());
  delay(500);
  ESP.restart();
}

/* main function task */
bool STA_Task(void) {
  bool ret = true;

  if (WiFi.status() == WL_CONNECTED) {
    // wait for time service is up
    if (fota_mode == true) {
      FOTAService();
    } else {
      if (TimeService() == true) {
        FbmService();
        yield();
        VM_run();
        yield();
      }
    }
  } else {
    DEBUG_PRINT("WiFi.status != WL_CONNECTED\n");
  }

  return ret;
}

void STA_Loop() {
  RF_Loop();
#if 0
  uint8_t in = digitalRead(BUTTON);

  if (in != sta_button) {
    sta_button = in;
    if (in == false) {
      // EE_EraseData();
      // Serial.printf("EEPROM erased\n");
      RF_executeIoEntryDB(1);
    }
  }
#endif
}
