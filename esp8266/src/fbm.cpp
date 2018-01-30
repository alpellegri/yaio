#include <Arduino.h>
#include <WiFiUDP.h>

#include <DHT.h>
#include <FirebaseArduino.h>

#include <stdio.h>
#include <string.h>

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

#define DHTPIN D6
#define DHTTYPE DHT22

#define FBM_UPDATE_TH (30 * 60)
#define FBM_UPDATE_MONITOR_FAST (1)
#define FBM_UPDATE_MONITOR_SLOW (5)
#define FBM_MONITOR_TIMERS (15)

DHT dht(DHTPIN, DHTTYPE);

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

String FBM_getResetReason() { return ESP.getResetReason(); }

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
    FirebaseObject fbobject = Firebase.get(kstartup);
    if (Firebase.failed()) {
      Serial.println(F("get failed: kstartup"));
      Serial.printf("%s\n", kstartup.c_str());
      Serial.print(Firebase.error());
    } else {
      JsonVariant variant = fbobject.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      if (object.success()) {
        bootcnt = object["bootcnt"];
        object["bootcnt"] = ++bootcnt;
        object["time"] = getTime();
        object["version"] = String(VERS_getVersion());
        yield();
        Firebase.set(kstartup, JsonVariant(object));
        if (Firebase.failed()) {
          bootcnt--;
          Serial.println(F("set failed: kstartup"));
          Serial.println(Firebase.error());
        } else {
          boot_sm = 2;
          Serial.println(F("firebase: configured!"));
          yield();
        }
      } else {
        Serial.println(F("parseObject() failed"));
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

      Serial.println(F("Node is up!"));
      control_time_last = 0;
      boot_sm = 21;
    }
  } break;

  case 21: {
    String kcontrol;
    FbSetPath_control(kcontrol);
    Firebase.setInt((kcontrol + F("/reboot")), 0);
    if (Firebase.failed()) {
      Serial.print(F("set failed: kcontrol/reboot"));
      Serial.println(Firebase.error());
    } else {
      dht.begin();
      boot_sm = 3;
    }
  } break;

  // firebase monitoring
  case 3: {
    uint32_t time_now = getTime();
    if ((time_now - fbm_update_last) >= ((fbm_monitor_run == true)
                                             ? (FBM_UPDATE_MONITOR_FAST)
                                             : (FBM_UPDATE_MONITOR_SLOW))) {
      Serial.printf_P(PSTR("boot_sm: %d - Heap: %d\n"), boot_sm,
                      ESP.getFreeHeap());
      fbm_update_last = time_now;

      String kcontrol;
      FbSetPath_control(kcontrol);
      control_time = Firebase.getInt(kcontrol + F("/time"));
      if (Firebase.failed() == true) {
        Serial.print(F("get failed: kcontrol/time"));
        Serial.println(Firebase.error());
      } else {
        if (control_time != control_time_last) {
          control_time_last = control_time;
          fbm_monitor_last = time_now;
          fbm_monitor_run = true;
        }
        if (fbm_monitor_run == true) {
          if ((time_now - fbm_monitor_last) > FBM_UPDATE_MONITOR_SLOW) {
            fbm_monitor_run = false;
          }

          FirebaseObject fbobject = Firebase.get(kcontrol);
          if (Firebase.failed() == true) {
            Serial.println(F("get failed: kcontrol"));
            Serial.print(Firebase.error());
          } else {
            JsonVariant variant = fbobject.getJsonVariant();
            JsonObject &object = variant.as<JsonObject>();
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
              Serial.println(F("parseObject() failed"));
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
          Firebase.set(kstatus, JsonVariant(status));
          if (Firebase.failed()) {
            Serial.print(F("set failed: kstatus"));
            Serial.println(Firebase.error());
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
