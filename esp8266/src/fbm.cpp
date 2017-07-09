#include <Arduino.h>
#include <WiFiUDP.h>

#include <DHT.h>
#include <FirebaseArduino.h>

#include <stdio.h>
#include <string.h>

#include "ee.h"
#include "fblog.h"
#include "fbm.h"
#include "fcm.h"
#include "rf.h"
#include "timesrv.h"

#define LED D0
#define DHTPIN D6
#define DHTTYPE DHT22

DHT dht(DHTPIN, DHTTYPE);

uint8_t boot_sm = 0;
bool status_alarm = false;
bool status_alarm_last = false;
bool control_alarm = false;
bool control_radio_learn = false;
bool control_monitor = false;

uint16_t fbm_task_cnt;
uint32_t heap_size = 0;
uint16_t fbm_monitorcnt = 0;
uint16_t bootcnt = 0;
uint32_t fbm_code_last = 0;
uint32_t fbm_time_last = 0;

uint32_t humidity_data;
uint32_t temperature_data;

/**
 * The target IP address to send the magic packet to.
 */
IPAddress computer_ip(192, 168, 1, 255);

/**
 * The targets MAC address to send the packet to
 */
byte mac[] = {0xD0, 0x50, 0x99, 0x5E, 0x4B, 0x0E};

void sendWOL(IPAddress addr, byte *mac, size_t size_of_mac) {
  const byte preamble[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
  byte i;

  WiFiUDP udp;

  udp.begin(9);
  yield();
  udp.beginPacket(addr, 8889);
  yield();
  udp.write(preamble, sizeof preamble);
  yield();
  for (i = 0; i < 16; i++) {
    udp.write(mac, size_of_mac);
    yield();
  }

  udp.endPacket();
  yield();
}

void FbmUpdateRadioCodes(void) {
  yield();

  Serial.printf("FbmUpdateRadioCodes Rx\n");
  FirebaseObject fbradio = Firebase.get("RadioCodes/Active");
  if (Firebase.failed() == true) {
    Serial.print("get failed: control");
    Serial.println(Firebase.error());
  } else {
    RF_ResetRadioCodeDB();
    JsonVariant variant = fbradio.getJsonVariant();
    JsonObject &object = variant.as<JsonObject>();
    for (JsonObject::iterator it = object.begin(); it != object.end(); ++it) {
      yield();
      Serial.println(it->key);
      String string = it->value.asString();
      Serial.println(string);
      RF_AddRadioCodeDB(string);
    }
  }

  Serial.printf("FbmUpdateRadioCodes Tx\n");
  fbradio = Firebase.get("RadioCodes/ActiveTx");
  if (Firebase.failed() == true) {
    Serial.print("get failed: control");
    Serial.println(Firebase.error());
  } else {
    RF_ResetRadioCodeTxDB();
    JsonVariant variant = fbradio.getJsonVariant();
    JsonObject &object = variant.as<JsonObject>();
    for (JsonObject::iterator it = object.begin(); it != object.end(); ++it) {
      yield();
      Serial.println(it->key);
      String string = it->value.asString();
      Serial.println(string);
      RF_AddRadioCodeTxDB(string);
    }
  }
}

/* main function task */
bool FbmService(void) {
  bool ret = false;

  // boot counter
  if (boot_sm == 0) {
    bool ret = true;
    char *firebase_url = NULL;
    char *firebase_secret = NULL;

    firebase_url = EE_GetFirebaseUrl();
    firebase_secret = EE_GetFirebaseSecret();
    Firebase.begin(firebase_url, firebase_secret);
    yield();
    Firebase.setBool("control/reboot", false);
    if (Firebase.failed()) {
      Serial.print("set failed: control/reboot");
      Serial.println(Firebase.error());
    } else {
      boot_sm = 1;
    }
  }
  yield();

  if (boot_sm == 1) {
    yield();
    FirebaseObject fbobject = Firebase.get("startup");
    if (Firebase.failed()) {
      Serial.println("set failed: status/bootcnt");
      Serial.println(Firebase.error());
    } else {
      JsonVariant variant = fbobject.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      if (object.success()) {
        bootcnt = object["bootcnt"];
        object["bootcnt"] = ++bootcnt;
        object["time"] = getTime();
        yield();
        Firebase.set("startup", JsonVariant(object));
        if (Firebase.failed()) {
          bootcnt--;
          Serial.println("set failed: status/bootcnt");
          Serial.println(Firebase.error());
        } else {
          boot_sm = 2;
          String str = String("boot-up complete");
          fblog_log(str, true);
        }
      } else {
        Serial.println("parseObject() failed");
      }
    }
  }

  if (boot_sm == 2) {
    if (++fbm_monitorcnt >= (5 / 1)) {
      uint32_t time_now = getTime();

      float h = dht.readHumidity();
      float t = dht.readTemperature();
      if (isnan(h) || isnan(t)) {
        Serial.println("Failed to read from DHT sensor!");
      } else {
        humidity_data = 10 * h;
        temperature_data = 10 * t;
      }

      Serial.println("FbmService - monitor");
      fbm_monitorcnt = 0;
      yield();
      FirebaseObject fbobject = Firebase.get("control");
      if (Firebase.failed() == true) {
        Serial.print("get failed: control");
        Serial.println(Firebase.error());
      } else {
        JsonVariant variant = fbobject.getJsonVariant();
        JsonObject &object = variant.as<JsonObject>();

        if (object.success()) {
          control_alarm = object["alarm"];
          control_radio_learn = object["radio_learn"];

          bool control_led = object["led"];
          digitalWrite(LED, !(control_led == true));
          if (control_led == true) {
            Serial.println("Sending WOL Packet...");
            yield();
            sendWOL(computer_ip, mac, sizeof mac);
          }

          bool control_reboot = object["reboot"];
          if (control_reboot == true) {
            ESP.restart();
          }

          control_monitor = object["monitor"];
        } else {
          Serial.println("parseObject() failed");
        }
      }

      if (control_monitor == true) {
        DynamicJsonBuffer jsonBuffer;
        JsonObject &status = jsonBuffer.createObject();
        status["alarm"] = status_alarm;
        // digitalWrite(LED, !(status_alarm == true));

        status["heap"] = ESP.getFreeHeap();
        status["humidity"] = humidity_data;
        status["temperature"] = temperature_data;
        status["time"] = time_now;
        yield();
        Firebase.set("status", JsonVariant(status));
        if (Firebase.failed()) {
          Serial.print("set failed: status");
          Serial.println(Firebase.error());
        }
      } else {
        yield();
        Firebase.set("status/time", time_now);
        if (Firebase.failed()) {
          Serial.print("set failed: status");
          Serial.println(Firebase.error());
        }
      }

      // convert to minutes
      uint32_t delta = (time_now - fbm_time_last) / 60;
      // log every 30 minutes
      if (delta > 30) {
        DynamicJsonBuffer jsonBuffer;
        JsonObject &th = jsonBuffer.createObject();
        th["time"] = time_now;
        th["t"] = temperature_data;
        th["h"] = humidity_data;
        yield();
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
    }

    // monitor for alarm activation
    if (status_alarm != control_alarm) {
      status_alarm = control_alarm;
      if (status_alarm == true) {
        // acquire Active Radio Codes from FB
        FbmUpdateRadioCodes();
      }
    }

    // manage RF activation/deactivation
    if ((status_alarm == true) || (control_radio_learn == true)) {
      RF_Enable();
    } else {
      RF_Disable();
    }

    // manage alarm activation/deactivation notifications
    if (status_alarm_last != status_alarm) {
      status_alarm_last = status_alarm;
      String str = "Alarm ";
      str += String((status_alarm == true) ? ("active") : ("inactive"));
      fblog_log(str, false);
    }

    // monitor for RF radio codes
    uint32_t code = RF_GetRadioCode();
    if (code != 0) {
      if (control_radio_learn == true) {
        // acquire Active Radio Codes from FB
        FbmUpdateRadioCodes();
        if (code != fbm_code_last) {
          if (RF_CheckRadioCodeDB(code) == false) {
            Serial.printf("RadioCodes/Inactive: %x\n", code);
            yield();
            Firebase.pushInt("RadioCodes/Inactive", code);
            if (Firebase.failed()) {
              Serial.print("set failed: RadioCodes/Inactive");
              Serial.println(Firebase.error());
            } else {
              fbm_code_last = code;
            }
          }
        }
      }

      if (RF_CheckRadioCodeDB(code) == true) {
        String str = String("Intrusion!!!");
        fblog_log(str, status_alarm);
      }
    }
  }

  return ret;
}
