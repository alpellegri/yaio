#include <Arduino.h>
#include <ArduinoJson.h>
#include <WiFiUDP.h>

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
#include <rom/rtc.h>

static uint8_t boot_sm = 0;
static bool boot_first = false;
static uint16_t bootcnt = 0;

String verbose_print_reset_reason(RESET_REASON reason) {
  String result;
  switch (reason) {
  case 1:
    result = F("Vbat power on reset");
    break;
  case 3:
    result = F("Software reset digital core");
    break;
  case 4:
    result = F("Legacy watch dog reset digital core");
    break;
  case 5:
    result = F("Deep Sleep reset digital core");
    break;
  case 6:
    result = F("Reset by SLC module, reset digital core");
    break;
  case 7:
    result = F("Timer Group0 Watch dog reset digital core");
    break;
  case 8:
    result = F("Timer Group1 Watch dog reset digital core");
    break;
  case 9:
    result = F("RTC Watch dog Reset digital core");
    break;
  case 10:
    result = F("Instrusion tested to reset CPU");
    break;
  case 11:
    result = F("Time Group reset CPU");
    break;
  case 12:
    result = F("Software reset CPU");
    break;
  case 13:
    result = F("RTC Watch dog Reset CPU");
    break;
  case 14:
    result = F("for APP CPU, reseted by PRO CPU");
    break;
  case 15:
    result = F("Reset when the vdd voltage is not stable");
    break;
  case 16:
    result = F("RTC Watch dog reset digital core and rtc module");
    break;
  default:
    result = F("NO_MEAN");
  }

  return result;
}

String FBM_getResetReason(void) {
  String ret;
  ret = F("CPU0: ");
  ret += verbose_print_reset_reason(rtc_get_reset_reason(0));
  ret += F("\nCPU1: ");
  ret += verbose_print_reset_reason(rtc_get_reset_reason(1));
  return ret;
}

/* main function task */
void FbmService(void) {

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
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    String kcontrol;
    FbSetPath_control(kcontrol);
    Firebase.stream(kcontrol + F("/time"));
    boot_sm = 31;
  } break;
  case 31: {
    String response;
    int code = Firebase.readEvent(response);
    if (code == -1) {
      boot_sm = 3;
    } else if (code > 0) {
      DEBUG_PRINT("response: _%s_\n", response.c_str());
#if 1
      String line = response.substring(7, response.indexOf('\n'));
      if (line.compareTo("put") == 0) {
        DEBUG_PRINT("preocessing\n");
        VM_UpdateDataReq();
        String kcontrol;
        FbSetPath_control(kcontrol);
        String json = Firebase.getJSON(kcontrol);
        if (Firebase.failed() == true) {
          DEBUG_PRINT("get failed: kcontrol\n");
          DEBUG_PRINT("%s\n", Firebase.error().c_str());
        } else {
          DynamicJsonBuffer jsonBuffer;
          JsonObject &object = jsonBuffer.parseObject(json);
          if (object.success()) {

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
        status["heap"] = ESP.getFreeHeap();
        status["time"] = getTime();

        DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());

        yield();
        String kstatus;
        FbSetPath_status(kstatus);
        Firebase.setJSON(kstatus, JsonVariant(status));
        if (Firebase.failed()) {
          DEBUG_PRINT("set failed: kstatus\n");
          DEBUG_PRINT("%s\n", Firebase.error().c_str());
        }
      }
#endif
    }
  } break;

  case 4:
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    STA_FotaReq();
    boot_sm = 50;
    break;

  case 5:
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    EE_EraseData();
    DEBUG_PRINT("EEPROM erased\n");
    ESP.restart();
    boot_sm = 50;
    break;

  default:
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    break;
  }
}
