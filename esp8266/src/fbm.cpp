#include <Arduino.h>
#include <DHT.h>

#include <FirebaseArduino.h>

#include <stdio.h>
#include <string.h>

#include "ee.h"

#define LED D0 // Led in NodeMCU at pin GPIO16 (D0).
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

bool FBM_Setup(void) {
  bool ret = true;
  char *firebase_url = NULL;
  char *firebase_secret = NULL;

  firebase_url = EE_GetFirebaseUrl();
  firebase_secret = EE_GetFirebaseSecret();

  Firebase.begin(firebase_url);

  return ret;
}

void FBM_Loop() {}

/* main function task */
bool FBM_Task(void) {
  bool ret = false;

  // boot counter
  if (boot == false) {
    Firebase.setBool("control/reboot", false);
    if (Firebase.failed()) {
      Serial.print("set failed: control/reboot");
      Serial.println(Firebase.error());
    } else {
      int bootcnt = Firebase.getInt("status/bootcnt");
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
          ret = true;
        }
      }
    }
  }

  if (boot == true) {
    // Serial.printf("fbm_logcnt: %d\n", fbm_monitorcnt);
    // every 5 second
    if (++fbm_monitorcnt == (5 / 1)) {
      fbm_monitorcnt = 0;

      int humidity_data = dht.readHumidity();
      int temperature_data = dht.readTemperature();
      // Serial.printf("t: %d, h: %d\n", temperature_data, humidity_data);

      bool control_monitor = Firebase.getBool("control/monitor");
      if ((Firebase.failed() == false) && (control_monitor == true)) {
        // get object data
        bool control_alarm = Firebase.getBool("control/alarm");
        if (Firebase.failed()) {
          Serial.print("get failed: control/alarm");
          Serial.println(Firebase.error());
        } else {
          if (status_alarm != control_alarm) {
            status_alarm = control_alarm;
            digitalWrite(LED, !(status_alarm == true));
            Firebase.setBool("status/alarm", status_alarm);
            if (Firebase.failed()) {
              Serial.print("set failed: status/alarm");
              Serial.println(Firebase.error());
            }
          }
        }
        // get object data
        bool control_reboot = Firebase.getBool("control/reboot");
        if (Firebase.failed()) {
          Serial.print("get failed: control/reboot");
          Serial.println(Firebase.error());
        } else {
          if (control_reboot == true) {
            ESP.restart();
          }
        }

        // get object data
        bool control_heap = Firebase.getBool("control/heap");
        if (Firebase.failed()) {
          Serial.print("get failed: control/heap");
          Serial.println(Firebase.error());
        } else {
          if (control_heap == true) {
            status_heap = ESP.getFreeHeap();
            Firebase.setInt("status/heap", status_heap);
            if (Firebase.failed()) {
              Serial.print("set failed: status/heap");
              Serial.println(Firebase.error());
            }
          }
        }

        Firebase.setInt("status/upcnt", fbm_task_cnt++);
        if (Firebase.failed()) {
          Serial.print("set failed: status/upcnt");
          Serial.println(Firebase.error());
        }

        Firebase.setInt("status/temperature", temperature_data);
        if (Firebase.failed()) {
          Serial.print("set failed: status/temperature");
          Serial.println(Firebase.error());
        }

        Firebase.setInt("status/humidity", humidity_data);
        if (Firebase.failed()) {
          Serial.print("set failed: status/humidity");
          Serial.println(Firebase.error());
        }
      } else {
        Serial.print("monitoring suspended\n");
      }

      Serial.printf("fbm_logcnt: %d\n", fbm_logcnt);
      // log every 15 minutes
      if (++fbm_logcnt == (60 * 15 / 5)) {
        fbm_logcnt = 0;
        Firebase.pushInt("logs/temperature", temperature_data);
        if (Firebase.failed()) {
          Serial.print("push failed: logs/temperature");
          Serial.println(Firebase.error());
        }

        Firebase.pushInt("logs/humidity", humidity_data);
        if (Firebase.failed()) {
          Serial.print("push failed: logs/humidity");
          Serial.println(Firebase.error());
        }
      }
    } else {
      Serial.print("fbm yield\n");
    }
  }

  return ret;
}
