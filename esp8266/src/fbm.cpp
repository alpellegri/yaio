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

static uint8_t boot_sm = 0;
static bool boot_first = false;
static uint32_t stream_time = 0;

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
      DynamicJsonDocument object(512);
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

  // firebase monitoring
  case 3: {
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    String kcontrol = FbGetPath_control();
    Firebase.stream(kcontrol + F("/time"));
    boot_sm = 31;
    stream_time = millis();
  } break;
  case 31: {
    String response;
    int code = Firebase.readEvent(response);
    uint32_t current_time = millis();
    if (code == -1) {
      boot_sm = 3;
    } else if (code == 0) {
      if ((current_time - stream_time) > (60 * 1000)) {
        DEBUG_PRINT("delta fail %d\n", (current_time - stream_time));
        boot_sm = 3;
      }
    } else {
      stream_time = current_time;
      DEBUG_PRINT("response: _%s_\n", response.c_str());

      String line = response.substring(7, response.indexOf('\n'));
      if (line.compareTo(F("put")) == 0) {
        DEBUG_PRINT("processing\n");
        bool run = false;
        VM_UpdateDataReq();
        String kcontrol = FbGetPath_control();
        String json = Firebase.getJSON(kcontrol);
        if (Firebase.failed() == true) {
          DEBUG_PRINT("get failed: kcontrol\n");
          DEBUG_PRINT("%s\n", Firebase.error().c_str());
        } else {
          DynamicJsonDocument object(512);
          auto error = deserializeJson(object, json);
          if (!error) {
            int control_reboot = object[F("reboot")];
            if (control_reboot == 0) {
              run = true;
            } else if (control_reboot == 1) {
              boot_sm = 6;
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

        if (run == true) {
          DynamicJsonDocument status(512);
          status[F("heap")] = ESP.getFreeHeap();
          status[F("time")] = getTime();
          struct tm timeinfo;
          time_t now = time(nullptr);
          gmtime_r(&now, &timeinfo);
          Serial.print("Current time: ");
          Serial.print(asctime(&timeinfo));

          DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());

          String status_str;
          serializeJson(status, status_str);
          String kstatus = FbGetPath_status();
          DEBUG_PRINT("set: kstatus\n");
          Firebase.setJSON(kstatus, status_str);
          DEBUG_PRINT("set: kstatus\n");
          if (Firebase.failed()) {
            DEBUG_PRINT("set failed: kstatus\n");
            DEBUG_PRINT("%s\n", Firebase.error().c_str());
          }
        }
      }
    }
    ret = true;
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
