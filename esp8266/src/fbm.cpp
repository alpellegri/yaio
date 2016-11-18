#include <Arduino.h>
#include <DHT.h>

#include <FirebaseArduino.h>

#include <stdio.h>
#include <string.h>

#include "ee.h"
#include "fbm.h"
#include "fcm.h"
#include "rf.h"
#include "timesrv.h"

#define LED D0
#define DHTPIN D6
#define DHTTYPE DHT22

DHT dht(DHTPIN, DHTTYPE);

bool boot = false;
bool status_alarm = false;
bool status_alarm_last = false;
bool control_alarm = false;
bool control_radio_learn = false;

uint16_t fbm_task_cnt;
uint32_t heap_size = 0;
uint16_t fbm_monitorcnt = 0;
uint16_t bootcnt = 0;
uint32_t fbm_code_last = 0;
uint32_t fbm_time_last = 0;

/* main function task */
bool FbmService(void) {
  bool ret = false;

  // boot counter
  if (boot == false) {
    bool ret = true;
    char *firebase_url = NULL;
    char *firebase_secret = NULL;

    firebase_url = EE_GetFirebaseUrl();
    firebase_secret = EE_GetFirebaseSecret();
    Firebase.begin(firebase_url, firebase_secret);

    Firebase.setBool("control/reboot", false);
    if (Firebase.failed()) {
      Serial.print("set failed: control/reboot");
      Serial.println(Firebase.error());
    } else {
      bootcnt = Firebase.getInt("status/bootcnt");
      if (Firebase.failed()) {
        Serial.print("get failed: status/bootcnt");
        Serial.println(Firebase.error());
      } else {
        Serial.printf("status/bootcnt: %d\n", bootcnt);
        bootcnt++;
        Firebase.setInt("status/bootcnt", bootcnt);
        if (Firebase.failed()) {
          Serial.print("set failed: status/bootcnt");
          Serial.println(Firebase.error());
        } else {
          boot = 1;
          String str = String(getTmUTC()) + String(" boot-up complete");
          FcmSendPush(str);
          Firebase.pushString("logs/Reports", str);
          // Firebase.pushString("logs/Reports/entry", "boot-up complete");
        }
      }
    }
  }

  if (boot == true) {

    // every 5 second
    if (++fbm_monitorcnt == (5 / 1)) {
      fbm_monitorcnt = 0;

      FirebaseObject fbcontrol = Firebase.get("control");
      if (Firebase.failed() == true) {
        Serial.print("get failed: control");
        Serial.println(Firebase.error());
      } else {
        JsonVariant variant = fbcontrol.getJsonVariant();
        JsonObject &object = variant.as<JsonObject>();

        control_alarm = object["alarm"];

        control_radio_learn = object["radio_learn"];

        bool control_led = object["led"];
        digitalWrite(LED, !(control_led == true));

        bool control_reboot = object["reboot"];
        if (control_reboot == true) {
          ESP.restart();
        }

        bool control_monitor = object["monitor"];
        if (control_monitor == true) {
          int humidity_data = 10 * dht.readHumidity();
          int temperature_data = 10 * dht.readTemperature();

          {
            StaticJsonBuffer<256> jsonBuffer;
            JsonObject &status = jsonBuffer.createObject();
            status["alarm"] = status_alarm;
            // digitalWrite(LED, !(status_alarm == true));

            status["bootcnt"] = bootcnt;
            status["fire"] = false;
            status["flood"] = false;
            status["heap"] = ESP.getFreeHeap();
            status["humidity"] = humidity_data;
            status["temperature"] = temperature_data;
            status["upcnt"] = fbm_task_cnt++;
            Firebase.set("status", JsonVariant(status));
            if (Firebase.failed()) {
              Serial.print("set failed: status");
              Serial.println(Firebase.error());
            }
          }

          // convert to minutes
          uint32_t time_now = getTime() / 60;
          // modulo 60 arithmetic
          uint32_t delta = (time_now - fbm_time_last);
          // log every 15 minutes
          if (delta > 15) {
            StaticJsonBuffer<128> jsonBuffer;
            JsonObject &th = jsonBuffer.createObject();
            th["time"] = time_now;
            th["t"] = temperature_data;
            th["h"] = humidity_data;
            Firebase.push("logs/TH", JsonVariant(th));
            if (Firebase.failed()) {
              Serial.print("push failed: logs/TH");
              Serial.println(Firebase.error());
            } else {
              // update in case of success
              fbm_time_last = time_now;
            }
          } else {
            /* do nothing */
          }
        } else {
          Serial.print("monitor suspended\n");
        }
      }
    }

    // monitor for alarm activation
    if (status_alarm != control_alarm) {
      status_alarm = control_alarm;
      if (status_alarm == true) {
        // acquire Active Radio Codes
        FirebaseObject fbradio = Firebase.get("RadioCodes/Active");
        if (Firebase.failed() == true) {
          Serial.print("get failed: control");
          Serial.println(Firebase.error());
        } else {
          fbm_code_last = 0;
          RF_ResetRadioCodeDB();
          JsonVariant variant = fbradio.getJsonVariant();
          JsonObject &object = variant.as<JsonObject>();
          for (JsonObject::iterator it = object.begin(); it != object.end();
               ++it) {
            Serial.println(it->key);
            String string = it->value.asString();
            Serial.println(string);
            RF_AddRadioCodeDB(string);
          }
        }
        RF_Enable();
      } else {
        RF_Disable();
      }
    }

    // log alarm status
    if (status_alarm_last != status_alarm) {
      status_alarm_last = status_alarm;
      String str = String(getTmUTC());
      if (status_alarm == true) {
        str += String(" Alarm active");
      } else {
        str += String(" Alarm inactive");
      }
      Serial.println(str);
      Firebase.pushString("logs/Reports", str);
    }

    // monitor for RF radio codes
    uint32_t code = RF_GetRadioCode();
    // Serial.printf("control_radio_learn: %d\n", control_radio_learn);
    if (status_alarm == true) {
      if (code != 0) {
        if (RF_CheckRadioCodeDB(code) == true) {
          String str = String(getTmUTC()) + String(" Intrusion!!!");
          Serial.print(str);
          FcmSendPush(str);
          Firebase.pushString("logs/Reports", str);
        } else {
          if (control_radio_learn == true) {
            if (code != fbm_code_last) {
              fbm_code_last = code;
              Serial.printf("RadioCodes/Inactive: %d\n", code);
              Firebase.pushInt("RadioCodes/Inactive", code);
            }
          }
        }
      }
    }
  } else {
    Serial.print("fbm yield\n");
  }

  return ret;
}
