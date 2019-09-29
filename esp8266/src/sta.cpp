#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <FS.h>

#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "ee.h"
#include "fbm.h"
#include "fota.h"
#include "pht.h"
#include "pio.h"
#include "rf.h"
#include "timers.h"
#include "timesrv.h"
#include "vm.h"

#define LED D0 // Led in NodeMCU at pin GPIO16 (D0).
#define LED_OFF HIGH
#define LED_ON LOW
#define BUTTON D3 // flash button at pin GPIO00 (D3)

#define STA_WIFI_TIMEOUT (5 * 60 * 1000)

static bool fota_mode = false;

bool STA_Setup(void) {
  bool ret = true;
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
  DEBUG_PRINT("\n");

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
    DEBUG_PRINT("not connected to router\n");
    ESP.restart();
  }

  return ret;
}

void STA_FotaReq(void) {
  SPIFFS.open(String(FPSTR("/fota.req")).c_str(), String(FPSTR("w")).c_str());
}

/* main function task */
bool STA_Task(uint32_t current_time) {
  bool ret = true;

  wl_status_t wifi_status = WiFi.status();
  if (wifi_status == WL_CONNECTED) {
    // wait for time service is up
    if (fota_mode == true) {
      FOTAService();
    } else {
      if (TimeService() == true) {
        bool vmSchedule = FbmService();
        if (vmSchedule == true) {
          yield();
          Timers_Service();
          RF_Loop();
          RF_Service();
          PHT_Service();
          PIO_Service();
          VM_run();
          yield();
          VM_runNet();
          yield();
        }
      }
    }
  } else {
    FbmOnDisconnect();
    ret = false;
  }

  return ret;
}

void STA_Loop() {
  // RF_Loop();
}
