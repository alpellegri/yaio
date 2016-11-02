#include <Arduino.h>
#include <DHT.h>

#include <FirebaseArduino.h>

#include <stdio.h>
#include <string.h>

#include "ee.h"
#include "fbm.h"
#include "fcm.h"
#include "rf.h"

#define LED D0
#define DHTPIN D6
#define DHTTYPE DHT22

DHT dht(DHTPIN, DHTTYPE);

bool boot = false;
bool status_alarm = false;
int fbm_task_cnt;
int heap_size = 0;
int status_heap = 0;
int fbm_logcnt = 0;
int fbm_monitorcnt = 0;
int bootcnt = 0;

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
        Firebase.setInt("status/bootcnt", bootcnt + 1);
        if (Firebase.failed()) {
          Serial.print("set failed: status/bootcnt");
          Serial.println(Firebase.error());
        } else {
          boot = 1;
          FcmSendPush((char *)"boot-up complete");
        }
      }
    }
  }

  if (boot == true) {
    // Serial.printf("fbm_logcnt: %d\n", fbm_monitorcnt);
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

        bool control_alarm = object["alarm"];

        if (status_alarm != control_alarm) {
          status_alarm = control_alarm;
          if (status_alarm == true) {
            RF_Enable();
          } else {
            RF_Disable();
          }
        }

        if (status_alarm == true) {
          uint32_t code;
          code = RF_GetRadioCode();
          if (code != 0) {
            FcmSendPush((char *)"Alarm intrusion!!!");
          }
        }

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

          Serial.printf("fbm_logcnt: %d\n", fbm_logcnt);
          // log every 15 minutes
          if (++fbm_logcnt == (60 * 15 / 5)) {
            fbm_logcnt = 0;
            StaticJsonBuffer<32> jsonBuffer;
            JsonObject &th = jsonBuffer.createObject();
            th["t"] = temperature_data;
            th["h"] = humidity_data;
            Firebase.push("logs/TH", JsonVariant(th));
            if (Firebase.failed()) {
              Serial.print("push failed: logs/TH");
              Serial.println(Firebase.error());
            }
          }
        } else {
          Serial.print("monitor suspended\n");
        }
      }
    }
  } else {
    Serial.print("fbm yield\n");
  }

  return ret;
}
