#include <Arduino.h>

#include <Preferences.h>
#include <WiFi.h>

#include <stdio.h>
#include <string.h>

#include "ap.h"
#include "ee.h"
#include "fbconf.h"
#include "fbm.h"
#include "fcm.h"
#include "fota.h"
#include "timesrv.h"
#include "vm.h"
#include "rf.h"
#include "timers.h"

#define LED 13
#define LED_OFF LOW
#define LED_ON HIGH

static uint8_t sta_button = 0x55;
static uint8_t sta_cnt = 0;
static bool fota_mode = false;

static Preferences preferences;

bool STA_Setup(void) {
  bool ret = true;
  bool sts = true;
  int cnt;

  digitalWrite(LED, LED_OFF);

  Serial.println(F("connecting mode STA"));
  Serial.println(F("Configuration parameters:"));

  delay(100);
  WiFi.mode(WIFI_STA);

  String sta_ssid = EE_GetSSID();
  String sta_password = EE_GetPassword();
  Serial.print(F("sta_ssid: "));
  Serial.println(sta_ssid);
  Serial.print(F("sta_password: "));
  Serial.println(sta_password);
  Serial.println(F("trying to connect..."));

  TimeSetup();

  WiFi.begin(sta_ssid.c_str(), sta_password.c_str());
  cnt = 0;
  while ((WiFi.status() != WL_CONNECTED) && (cnt++ < 30)) {
    Serial.print(F("."));
    delay(500);
  }
  Serial.println();

  preferences.begin("my-app", false);

  if (WiFi.status() == WL_CONNECTED) {
    Serial.print(F("connected: "));
    Serial.println(WiFi.localIP());

    uint32_t req = preferences.getUInt("fota-req", 2);
    if (req == 0) {
      fota_mode = false;
    } else if (req == 1) {
      fota_mode = true;
      preferences.putUInt("fota-req", 0);
      FOTA_UpdateReq();
    } else {
      preferences.putUInt("fota-req", 0);
    }
  } else {
    sts = false;
  }

  if (sts != true) {
    Serial.println(F("not connected to router"));
    ESP.restart();
    ret = false;
  }

  return ret;
}

void STA_FotaReq(void) {
  preferences.putUInt("fota-req", 1);
  delay(500);
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
        FbmService();
        yield();
        VM_run();
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
