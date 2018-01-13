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
static bool status_alarm = false;
static bool status_alarm_last = false;
static bool control_alarm = false;
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

/**
 * The target IP address to send the magic packet to.
 */
static IPAddress computer_ip(192, 168, 1, 255);

/**
 * The targets MAC address to send the packet to
 */
static byte mac[] = {0xD0, 0x50, 0x99, 0x5E, 0x4B, 0x0E};

String FBM_getResetReason() { return ESP.getResetReason(); }

#define FBM_LOGIC_QUEUE_LEN 3
typedef struct {
  uint8_t func;
  uint8_t value;
  uint8_t src_idx;
} FbmFuncSrvQueque_t;

static uint8_t FbmLogicQuequeWrPos = 0;
static uint8_t FbmLogicQuequeRdPos = 0;
static FbmFuncSrvQueque_t FbmLogicQueque[FBM_LOGIC_QUEUE_LEN];

void FbmLogicReq(uint8_t src_idx, uint8_t port, bool value) {
  FbmLogicQueque[FbmLogicQuequeWrPos].src_idx = src_idx;
  FbmLogicQueque[FbmLogicQuequeWrPos].func = port;
  FbmLogicQueque[FbmLogicQuequeWrPos].value = value;
  FbmLogicQuequeWrPos++;
  if (FbmLogicQuequeWrPos >= FBM_LOGIC_QUEUE_LEN) {
    FbmLogicQuequeWrPos = 0;
  }
  if (FbmLogicQuequeWrPos == FbmLogicQuequeRdPos) {
    Serial.println(F("FbmLogicQueque overrun"));
  }
}

/* function mapping requests
 * port=0: value=1 -> arm alarm / value=0 -> disarm alarm
 * port=1: value=1 -> notify
 */
static bool FbmLogicAction(uint32_t src_idx, uint8_t port, bool value) {
  bool ret = false;
  if (port == 0) {
    Firebase.setBool((kcontrol + F("/alarm")), value);
    if (Firebase.failed()) {
    } else {
      ret = true;
    }
  } else if (port == 1) {
    String str = String(F("Event triggered on: ")) +
                 FB_getIoEntryNameById(src_idx) + String(F(" !!!"));
    fblog_log(str, status_alarm);
    ret = true;
  } else {
    ret = true;
  }

  return ret;
}

void FbmLogicSrv() {
  if (FbmLogicQuequeWrPos != FbmLogicQuequeRdPos) {
    bool ret = FbmLogicAction(FbmLogicQueque[FbmLogicQuequeRdPos].src_idx,
                              FbmLogicQueque[FbmLogicQuequeRdPos].func,
                              FbmLogicQueque[FbmLogicQuequeRdPos].value);
    if (ret == true) {
      FbmLogicQuequeRdPos++;
      if (FbmLogicQuequeRdPos >= FBM_LOGIC_QUEUE_LEN) {
        FbmLogicQuequeRdPos = 0;
      }
    }
  }
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
    boot_sm = 1;
    yield();
  } break;

  // firebase control/status init
  case 1: {
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
      RF_Disable();
      status_alarm = false;
      control_time_last = 0;
      boot_sm = 21;
    }
  } break;

  case 21: {
    Firebase.setInt((kcontrol + F("/reboot")), 0);
    if (Firebase.failed()) {
      Serial.print(F("set failed: kcontrol/reboot"));
      Serial.println(Firebase.error());
    } else {
      RF_Enable();
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
      // Serial.printf_P(PSTR("boot_sm: %d - Heap: %d\n"), boot_sm,
      //               ESP.getFreeHeap());
      fbm_update_last = time_now;

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
          Firebase.set(kstatus, JsonVariant(status));
          if (Firebase.failed()) {
            Serial.print(F("set failed: kstatus"));
            Serial.println(Firebase.error());
          }
        }
        yield();
      }
    }

    // call function service
    FbmLogicSrv();
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
