#include <Arduino.h>
#include <WiFiUDP.h>
#include <cJSON.h>

#include <stdio.h>
#include <string.h>
#include <time.h>

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
      cJSON *object = cJSON_Parse(json.c_str());
      if (object != NULL) {
        cJSON *data;
        cJSON *newdata;
        data = cJSON_GetObjectItemCaseSensitive(object, FPSTR("bootcnt"));
        newdata = cJSON_CreateNumber(data->valueint + 1);
        cJSON_ReplaceItemInObjectCaseSensitive(object, FPSTR("bootcnt"),
                                               newdata);
        data = cJSON_GetObjectItemCaseSensitive(object, FPSTR("time"));
        newdata = cJSON_CreateNumber(getTime());
        cJSON_ReplaceItemInObjectCaseSensitive(object, FPSTR("time"), newdata);
        data = cJSON_GetObjectItemCaseSensitive(object, FPSTR("version"));
        newdata = cJSON_CreateString((char *)VERS_getVersion().c_str());
        cJSON_ReplaceItemInObjectCaseSensitive(object, FPSTR("version"),
                                               newdata);
        char *string = cJSON_Print(object);
        yield();
        Firebase.updateJSON(kstartup, String(string));
        free(string);
        cJSON_Delete(object);
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
    ret = true;
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
      if (line.compareTo(F("put")) == 0) {
        DEBUG_PRINT("processing\n");
        VM_UpdateDataReq();
        String kcontrol = FbGetPath_control();
        String json = Firebase.getJSON(kcontrol);
        if (Firebase.failed() == true) {
          DEBUG_PRINT("get failed: kcontrol\n");
          DEBUG_PRINT("%s\n", Firebase.error().c_str());
        } else {
          cJSON *control = cJSON_Parse(json.c_str());
          if (control != NULL) {
            cJSON *data =
                cJSON_GetObjectItemCaseSensitive(control, FPSTR("reboot"));
            int control_reboot = data->valueint;
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
          cJSON_Delete(control);
        }
#if 1
        cJSON *status = cJSON_CreateObject();
        cJSON *data;
        data = cJSON_CreateNumber(ESP.getFreeHeap());
        cJSON_AddItemToObject(status, FPSTR("heap"), data);
        data = cJSON_CreateNumber(getTime());
        cJSON_AddItemToObject(status, FPSTR("time"), data);
        struct tm timeinfo;
        time_t now = time(nullptr);
        gmtime_r(&now, &timeinfo);
        Serial.print("Current time: ");
        Serial.print(asctime(&timeinfo));

        DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());

        yield();
        String kstatus = FbGetPath_status();
        char *string = cJSON_Print(status);
        Firebase.setJSON(kstatus, String(string));
        free(string);
        cJSON_Delete(status);
        if (Firebase.failed()) {
          DEBUG_PRINT("set failed: kstatus\n");
          DEBUG_PRINT("%s\n", Firebase.error().c_str());
        }
#endif
      }
#endif
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

  default:
    DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
    break;
  }

  return ret;
}
