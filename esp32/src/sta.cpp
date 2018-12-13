#include <Arduino.h>

#include <Preferences.h>
#include <WiFi.h>

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

#define LED 13
#define LED_OFF LOW
#define LED_ON HIGH
#define STA_WIFI_TIMEOUT (5 * 60 * 1000)

static bool fota_mode = false;

static Preferences preferences;
static uint32_t last_wifi_time;
static uint32_t core0_time;
static uint32_t core0_time2;

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
  DEBUG_PRINT("\n");

  preferences.begin("my-app", false);

  if (WiFi.status() == WL_CONNECTED) {
    TimeSetup();
    RF_Setup();

    DEBUG_PRINT("connected: ");
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
    DEBUG_PRINT("not connected to router\n");
    ESP.restart();
    ret = false;
  }

  return ret;
}

void STA_FotaReq(void) { preferences.putUInt("fota-req", 1); }

volatile bool vmSchedule = false;
bool coreTaskCreate = false;

void coreTask(void *pvParameters) {

  while (true) {
    if (vmSchedule == true) {
      core0_time = millis();
      Timers_Service();
      RF_Loop();
      RF_Service();
      PHT_Service();
      PIO_Service();
      VM_run();
      core0_time2 = millis();
    }
    delay(50);
  }
}

/* main function task */
bool STA_Task(uint32_t current_time) {
  bool ret = true;

  wl_status_t wifi_status = WiFi.status();
  if (wifi_status == WL_CONNECTED) {
    last_wifi_time = current_time;
    // wait for time service is up
    if (fota_mode == true) {
      FOTAService();
    } else {
      if (TimeService() == true) {
        vmSchedule = FbmService();
        if ((vmSchedule == true) && (coreTaskCreate == false)) {
          coreTaskCreate = true;
          core0_time = current_time;
          xTaskCreatePinnedToCore(coreTask, /* Function to implement the task */
                                  "coreTask", /* Name of the task */
                                  10000,      /* Stack size in words */
                                  NULL,       /* Task input parameter */
                                  1,          /* Priority of the task */
                                  NULL,       /* Task handle. */
                                  0); /* Core where the task should run */

          DEBUG_PRINT("Task created...\n");
        }
        yield();
        if (vmSchedule == true) {
          VM_runNet();
          yield();
          current_time = millis();
          if ((int32_t)(current_time - core0_time) > 50) {
            DEBUG_PRINT("hang: %d %d\n", current_time - core0_time,
                        core0_time2 - core0_time);
          }
          if ((int32_t)(current_time - core0_time) > 500) {
            DEBUG_PRINT("reset hang: %d\n", current_time - core0_time);
            ESP.restart();
          }
        }
      }
    }
  } else {
    DEBUG_PRINT("WiFi.status: %d\n", wifi_status);
    if ((current_time - last_wifi_time) > STA_WIFI_TIMEOUT) {
      // force reboot
      ESP.restart();
    }
  }

  return ret;
}

void STA_Loop() {}
