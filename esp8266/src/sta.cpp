#include <Arduino.h>

#include <ESP8266WiFi.h>
#include <WiFiClient.h>

#include <FirebaseArduino.h>
#include <DHT.h>

#include <stdio.h>
#include <string.h>

#include "ap.h"
#include "ee.h"
#include "fcm.h"

#define LED D0    // Led in NodeMCU at pin GPIO16 (D0).
#define BUTTON D3 // flash button at pin GPIO00 (D3)

#define DHTPIN 2
#define DHTTYPE DHT22

DHT dht(DHTPIN, DHTTYPE);

bool trig_push = false;
bool boot = false;
bool status_alarm = false;
int sta_task_cnt;
int heap_size = 0;
int status_heap = 0;
int sta_button = 0x55;

bool STA_Setup(void) {
  bool ret = true;
  bool sts = false;
  int cnt;
  char *sta_ssid = NULL;
  char *sta_password = NULL;
  char *firebase_url = NULL;
  char *firebase_secret = NULL;

  digitalWrite(LED, true);
  sta_task_cnt = 0;

  WiFi.disconnect();
  WiFi.softAPdisconnect(true);

  Serial.printf("connecting mode STA\n");
  Serial.printf("Configuration parameters:\n");
  sts = EE_LoadData();
  if (sts == true) {
    WiFi.mode(WIFI_STA);
    WiFi.disconnect();
    delay(100);
    WiFi.mode(WIFI_STA);

    sta_ssid = EE_GetSSID();
    sta_password = EE_GetPassword();
    firebase_url = EE_GetFirebaseUrl();
    firebase_secret = EE_GetFirebaseSecret();
    Serial.printf("sta_ssid: %s\n", sta_ssid);
    Serial.printf("sta_password: %s\n", sta_password);
    Serial.printf("\ntrying to connect...\n");
    WiFi.begin(sta_ssid, sta_password);
    cnt = 0;
    while ((WiFi.status() != WL_CONNECTED) && (cnt++ < 30)) {
      Serial.print(".");
      delay(500);
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.println();
      Serial.print("connected: ");
      Serial.println(WiFi.localIP());
      Firebase.begin(firebase_url);
    } else {
      sts = false;
    }
  }

  if (sts != true) {
    Serial.println();
    Serial.println("not connected to router");
    ret = false;
  }

  return ret;
}

void STA_Loop() {
  int in = digitalRead(BUTTON);

  if (in != sta_button) {
    sta_button = in;
    // Firebase.setBool("status/button", sta_button);
    // if (Firebase.failed()) {
    //   Serial.print("set failed: status/button");
    //   Serial.println(Firebase.error());
    // }
    if ((status_alarm == true) && (in == false)) {
      trig_push = true;
    }
    // if (in == false) {
    //   char payload[11] = "reset";
    //   int len = strlen(payload);
    //   Serial.println("reset eeprom");
    //   EE_StoreData((uint8_t *)payload, len);
    // }
  }
}

/* main function task */
bool STA_Task(void) {
  bool ret = true;

  int humidity_data = (int)dht.readHumidity();
  int temperature_data = (int)dht.readTemperature();

  sta_task_cnt++;
  Serial.printf("task_cnt: %d\n", sta_task_cnt);

  if (WiFi.status() == WL_CONNECTED) {
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
            trig_push = true;
          }
        }
      }
    }

    if (boot == true) {
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

        Firebase.setInt("status/upcnt", sta_task_cnt);
        if (Firebase.failed()) {
          Serial.print("set failed: status/upcnt");
          Serial.println(Firebase.error());
        }
      } else {
        Serial.print("monitoring suspended\n");
      }
    }

    if (trig_push == true) {
      trig_push = false;
      FcmSendPush();
    }
    FcmService();
  } else {
    Serial.print("WiFi.status != WL_CONNECTED\n");
  }

  return ret;
}
