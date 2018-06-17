#include <Arduino.h>
#include <WiFiUDP.h>

#include <stdio.h>
#include <string.h>

#include "ee.h"
#include "fbconf.h"
#include "fblog.h"
#include "fbm.h"
#include "fbutils.h"
#include "fcm.h"
#include "firebase.h"
#include "rf.h"
#include "sta.h"
#include "timers.h"
#include "timesrv.h"
#include "vers.h"
#include "vm.h"
#include "debug.h"

#define FBM_UPDATE_MONITOR_FAST (1)
#define FBM_UPDATE_MONITOR_SLOW (5)

static uint8_t boot_sm = 0;
static bool boot_first = false;
static uint32_t control_time;
static uint32_t control_time_last;

static uint16_t bootcnt = 0;
static uint32_t fbm_update_last = 0;
static uint32_t fbm_monitor_last = 0;
static bool fbm_monitor_run = false;

String FBM_getResetReason() { return ESP.getResetReason(); }

/* main function task */
void FbmService(void) {
  DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
  switch (boot_sm) {
  // firebase init
  case 0: {
    String firebase_url = EE_GetFirebaseUrl();
    String firebase_secret = EE_GetFirebaseSecret();
    Firebase.begin(firebase_url, firebase_secret);
    dump_path();
    boot_sm = 1;
    yield();
  } break;

  // firebase control/status init
  case 1: {
    String kstartup;
    FbSetPath_startup(kstartup);
    String json = Firebase.getJSON(kstartup);
    if (Firebase.failed()) {
      DEBUG_PRINT("get failed: kstartup\n");
      DEBUG_PRINT("%s\n", Firebase.error().c_str());
    } else {
      DynamicJsonBuffer jsonBuffer;
      JsonObject &object = jsonBuffer.parseObject(json);
      if (object.success()) {
        bootcnt = object["bootcnt"];
        object["bootcnt"] = ++bootcnt;
        object["time"] = getTime();
        object["version"] = String(VERS_getVersion());
        yield();
        Firebase.updateJSON(kstartup, JsonVariant(object));
        if (Firebase.failed()) {
          bootcnt--;
          DEBUG_PRINT("update failed: kstartup\n");
          DEBUG_PRINT("%s\n", Firebase.error().c_str());
        } else {
          boot_sm = 2;
          DEBUG_PRINT("firebase: configured!\n");
          yield();
        }
      } else {
        DEBUG_PRINT("parseObject() failed\n");
      }
    }
  } break;

  // firebase init DB
  case 2: {
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
    String kcontrol;
    FbSetPath_control(kcontrol);
    Firebase.setInt((kcontrol + F("/reboot")), 0);
    if (Firebase.failed()) {
      DEBUG_PRINT("set failed: kcontrol/reboot\n");
      DEBUG_PRINT("%s\n", Firebase.error().c_str());
    } else {
      boot_sm = 3;
    }
  } break;

  // firebase monitoring
  case 3: {
    uint32_t time_now = getTime();
    if ((time_now - fbm_update_last) >= ((fbm_monitor_run == true)
                                             ? (FBM_UPDATE_MONITOR_FAST)
                                             : (FBM_UPDATE_MONITOR_SLOW))) {
      fbm_update_last = time_now;
      DEBUG_PRINT("boot_sm: %d - update\n", boot_sm);

      String kcontrol;
      FbSetPath_control(kcontrol);
      yield();
      control_time = Firebase.getInt(kcontrol + F("/time"));
      if (Firebase.failed() == true) {
        DEBUG_PRINT("get failed: kcontrol/time\n");
        DEBUG_PRINT("%s\n", Firebase.error().c_str());
      } else {
        if (control_time != control_time_last) {
          control_time_last = control_time;
          fbm_monitor_last = time_now;
          VM_UpdateDataReq();
          fbm_monitor_run = true;
        }
        if (fbm_monitor_run == true) {
          if ((time_now - fbm_monitor_last) > FBM_UPDATE_MONITOR_SLOW) {
            fbm_monitor_run = false;
          }

          String json = Firebase.getJSON(kcontrol);
          if (Firebase.failed() == true) {
            DEBUG_PRINT("get failed: kcontrol\n");
            DEBUG_PRINT("%s\n", Firebase.error().c_str());
          } else {
            DynamicJsonBuffer jsonBuffer;
            JsonObject &object = jsonBuffer.parseObject(json);
            if (object.success()) {
              // control_alarm = object["alarm"];
              control_time = object["time"];

              int control_reboot = object["reboot"];
              if (control_reboot == 1) {
                ESP.restart();
              } else if (control_reboot == 2) {
                boot_sm = 4;
              } else if (control_reboot == 3) {
                boot_sm = 2;
              } else if (control_reboot == 4) {
                boot_sm = 5;
              }
            } else {
              DEBUG_PRINT("parseObject() failed\n");
            }
          }

          DynamicJsonBuffer jsonBuffer;
          JsonObject &status = jsonBuffer.createObject();
          // status["alarm"] = status_alarm;
          status["heap"] = ESP.getFreeHeap();
          status["time"] = time_now;
          yield();
          String kstatus;
          FbSetPath_status(kstatus);
          Firebase.setJSON(kstatus, JsonVariant(status));
          if (Firebase.failed()) {
            DEBUG_PRINT("set failed: kstatus\n");
            DEBUG_PRINT("%s\n", Firebase.error().c_str());
          }
        }
        yield();
      }
    }
  } break;

  case 4:
    STA_FotaReq();
    boot_sm = 50;
    break;
  case 5:
    EE_EraseData();
    DEBUG_PRINT("EEPROM erased\n");
    ESP.restart();
    boot_sm = 50;
    break;
  default:
    break;
  }
}
