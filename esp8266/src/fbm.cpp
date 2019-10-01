#include <Arduino.h>
#include <ArduinoJson.h>

#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "ee.h"
#include "fbconf.h"
#include "fblog.h"
#include "fbm.h"
#include "fcm.h"
#include "firebase.h"
#include "sta.h"
#include "timesrv.h"
#include "vers.h"
#include "vm.h"

#define FBM_UPDATE_MONITOR_FAST (1)
#define FBM_UPDATE_MONITOR_SLOW (5)

static uint8_t boot_sm = 0;
static bool boot_first = false;
static uint32_t control_time;
static uint32_t control_time_last;

static uint32_t fbm_update_last = 0;
static uint32_t fbm_monitor_last = 0;
static bool fbm_monitor_run = false;

String FBM_getResetReason(void) { return ESP.getResetReason(); }
void FbmOnDisconnect(void) { boot_sm = 3; }

/* main function task */
bool FbmService(void) {
  bool ret = false;

  // DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
  switch (boot_sm) {
  // firebase init
  case 0: {
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    String firebase_url = EE_GetFirebaseUrl();
    String firebase_secret = EE_GetFirebaseSecret();
    Firebase.begin(firebase_url, firebase_secret);
    dump_path();
    boot_sm = 1;
    yield();
  } break;

  // firebase control/status init
  case 1: {
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    String kstartup = FbGetPath_startup();
    String json = Firebase.getJSON(kstartup);
    if (Firebase.failed()) {
      DEBUG_PRINT("get failed: kstartup\n");
      DEBUG_PRINT("%s\n", Firebase.error().c_str());
    } else {
      DynamicJsonDocument object(1024);
      auto error = deserializeJson(object, json);
      if (!error) {
        uint32_t bootcnt = object[F("bootcnt")];
        object[F("bootcnt")] = bootcnt + 1;
        object[F("time")] = getTime();
        object[F("version")] = VERS_getVersion();
        String object_str;
        serializeJson(object, object_str);
        Firebase.updateJSON(kstartup, object_str);
        if (Firebase.failed()) {
          DEBUG_PRINT("update failed: kstartup\n");
          DEBUG_PRINT("%s\n", Firebase.error().c_str());
        } else {
          boot_sm = 2;
          DEBUG_PRINT("firebase: configured!\n");
          yield();
        }
      } else {
        DEBUG_PRINT("parseObject() failed\n");
        boot_sm = 5;
      }
    }
  } break;

  // firebase init DB
  case 2: {
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    bool res = FbGetDB();
    if (res == true) {
      if (boot_first == false) {
        boot_first = true;
        String str = FBM_getResetReason();
        fblog_log(str, true);
      }

      DEBUG_PRINT("Node is up!\n");
      control_time_last = 0;
      boot_sm = 21;
    }
  } break;

  case 21: {
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    String kcontrol = FbGetPath_control();
    Firebase.setInt((kcontrol + F("/reboot")), 0);
    if (Firebase.failed()) {
      DEBUG_PRINT("set failed: kcontrol/reboot\n");
      DEBUG_PRINT("%s\n", Firebase.error().c_str());
    } else {
      boot_sm = 3;
    }
  } break;

  // firebase monitoring / read
  case 3: {
    ret = true;
    uint32_t time_now = getTime();
    if ((time_now - fbm_update_last) >= ((fbm_monitor_run == true)
                                             ? (FBM_UPDATE_MONITOR_FAST)
                                             : (FBM_UPDATE_MONITOR_SLOW))) {
      DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
      fbm_update_last = time_now;

      String kcontrol = FbGetPath_control();
      String json = Firebase.getJSON(kcontrol);
      if (Firebase.failed() == true) {
        DEBUG_PRINT("get failed: kcontrol/time\n");
        DEBUG_PRINT("%s\n", Firebase.error().c_str());
      } else {
        DynamicJsonDocument object(1024);
        auto error = deserializeJson(object, json);
        if (!error) {
          control_time = object[F("time")];
          uint32_t control_reboot = object[F("reboot")];
          if (control_time != control_time_last) {
            control_time_last = control_time;
            fbm_monitor_last = time_now;
            VM_UpdateDataReq();
            fbm_monitor_run = true;
            boot_sm = 32;
          }
          if (fbm_monitor_run == true) {
            if ((time_now - fbm_monitor_last) > FBM_UPDATE_MONITOR_SLOW) {
              fbm_monitor_run = false;
            }
          }
          if (control_reboot == 1) {
            boot_sm = 6;
          } else if (control_reboot == 2) {
            boot_sm = 4;
          } else if (control_reboot == 3) {
            boot_sm = 2;
          } else if (control_reboot == 4) {
            boot_sm = 5;
          } else {
          }
        } else {
          DEBUG_PRINT("parseObject() failed\n");
        }
      }
    }
  } break;

  // firebase monitoring / write
  case 32: {
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    ret = true;
    DynamicJsonDocument status(1024);
    status[F("heap")] = ESP.getFreeHeap();
    status[F("time")] = getTime();
    String status_str;
    serializeJson(status, status_str);
    String kstatus = FbGetPath_status();
    Firebase.setJSON(kstatus, status_str);
    if (Firebase.failed()) {
      DEBUG_PRINT("set failed: kstatus\n");
      DEBUG_PRINT("%s\n", Firebase.error().c_str());
    } else {
      boot_sm = 3;
    }
  } break;

  case 4:
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    STA_FotaReq();
    delay(500);
    ESP.restart();
    break;

  case 5:
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    EE_EraseData();
    DEBUG_PRINT("EEPROM erased\n");
    ESP.restart();
    break;

  case 6:
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    ESP.restart();
    break;

  default:
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    break;
  }

  return ret;
}
