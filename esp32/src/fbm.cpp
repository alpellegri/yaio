#include <Arduino.h>
#include <WiFiUDP.h>

#include <DHT.h>

#include <stdio.h>
#include <string.h>

#include "firebase.h"
#include "ee.h"
#include "fbconf.h"
#include "fblog.h"
#include "fbm.h"
#include "fbutils.h"
#include "fcm.h"
#include "rf.h"
#include "sta.h"
#include "timers.h"
#include "timesrv.h"
#include "vers.h"
#include "vm.h"
#include <rom/rtc.h>

#define DEBUG_PRINT(fmt, ...) Serial.printf_P(PSTR(fmt), ##__VA_ARGS__)

#define DHTPIN 21
#define DHTTYPE DHT22

#define FBM_UPDATE_TH (30 * 60)
#define FBM_UPDATE_MONITOR_FAST (1)
#define FBM_UPDATE_MONITOR_SLOW (5)
#define FBM_MONITOR_TIMERS (15)

DHT *dht;

static uint8_t boot_sm = 0;
static bool boot_first = false;
static uint32_t control_time;
static uint32_t control_time_last;

static uint16_t bootcnt = 0;
static uint32_t fbm_update_last = 0;
static uint32_t fbm_time_th_last = 0;
static uint32_t fbm_monitor_last = 0;
static bool fbm_monitor_run = false;

static bool ht_monitor_run = false;
static float humidity_data;
static float temperature_data;

static uint32_t fbm_update_timer_last;

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

  switch (boot_sm) {
  // firebase init
  case 0: {
    bool ret = true;

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
      JsonObject& object = jsonBuffer.parseObject(json);
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

  // firebase timer/radio init
  case 2: {
    bool res = FbmUpdateRadioCodes();
    if (res == true) {
      if (boot_first == false) {
        boot_first = true;
        String str = F("\n");
        str += FBM_getResetReason();
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
      DEBUG_PRINT("set failed: kcontrol/reboot");
      DEBUG_PRINT("%s\n", Firebase.error().c_str());
    } else {
      dht = new DHT(DHTPIN, DHTTYPE);
      dht->begin();
      boot_sm = 3;
    }
  } break;

  // firebase monitoring
  case 3: {
    uint32_t time_now = getTime();
    if ((time_now - fbm_update_last) >= ((fbm_monitor_run == true)
                                             ? (FBM_UPDATE_MONITOR_FAST)
                                             : (FBM_UPDATE_MONITOR_SLOW))) {
      DEBUG_PRINT("boot_sm: %d - Heap: %d\n", boot_sm, ESP.getFreeHeap());
      fbm_update_last = time_now;

      String kcontrol;
      FbSetPath_control(kcontrol);
      float h = dht->readHumidity();
      float t = dht->readTemperature();
      DEBUG_PRINT("t: %f - h: %f\n", t, h);
      if (isnan(h) || isnan(t)) {
        ht_monitor_run = false;
      } else {
        ht_monitor_run = true;
        humidity_data = h;
        temperature_data = t;
      }
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
            JsonObject& object = jsonBuffer.parseObject(json);
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
    boot_sm = 5;
    break;
  default:
    break;
  }

  return ret;
}
