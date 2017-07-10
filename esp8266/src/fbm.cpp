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
bool control_radio_update = false;
bool control_monitor = false;

uint16_t fbm_task_cnt;
uint32_t heap_size = 0;
uint16_t fbm_monitorcnt = 0;
uint16_t bootcnt = 0;
uint32_t fbm_code_last = 0;
uint32_t fbm_time_last = 0;

uint32_t humidity_data;
uint32_t temperature_data;

uint16_t fbm_timer_monitor_cnt;

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

bool FbmUpdateRadioCodes(void) {
  bool ret = true;
  yield();

  if (ret == true)
  {
    Serial.printf("FbmUpdateRadioCodes Rx\n");
    FirebaseObject ref = Firebase.get("RadioCodes/Active");
    if (Firebase.failed() == true) {
      Serial.print("get failed: RadioCodes/Active");
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_ResetRadioCodeDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject& nestedObject = i->value;
        String action = nestedObject["action"];
        String action_d = nestedObject["action_d"];
        String delay = nestedObject["delay"];
        String id = nestedObject["id"];
        Serial.println(id);
        RF_AddRadioCodeDB(id, action, delay, action_d);
      }
    }
  }

  if (ret == true)
  {
    Serial.printf("FbmUpdateRadioCodes Tx\n");
    FirebaseObject ref = Firebase.get("RadioCodes/ActiveTx");
    if (Firebase.failed() == true) {
      Serial.print("get failed: RadioCodes/ActiveTx");
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_ResetRadioCodeTxDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject& nestedObject = i->value;
        String id = nestedObject["id"];
        Serial.println(id);
        RF_AddRadioCodeTxDB(id);
      }
    }
  }

  if (ret == true)
  {
    Serial.printf("FbmUpdateRadioCodes Timers\n");
    FirebaseObject ref = Firebase.get("Timers");
    if (Firebase.failed() == true) {
      Serial.print("get failed: Timers");
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_ResetTimerDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject& nestedObject = i->value;
        String action = nestedObject["action"];
        String hour = nestedObject["hour"];
        String minute = nestedObject["minute"];
        Serial.println(action);
        RF_AddTimerDB(action, hour, minute);
      }
    }
  }

  return ret;
}

/* main function task */
bool FbmService(void) {
  bool ret = false;

  Serial.printf("boot_sm: %d\n", boot_sm);
  // firebase connect
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
      Serial.println("set failed: control/reboot");
      Serial.println(Firebase.error());
    } else {
      Serial.print("firebase: connected!");
      Serial.println("firebase: connected!");
      boot_sm = 1;
    }
  }
  yield();

  // firebase control/status init
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
          String str = String("boot-up complete!");
          fblog_log(str, true);
        }
      } else {
        Serial.println("parseObject() failed");
      }
    }
  }

  // firebase timer/radio init
  if (boot_sm == 2) {
    bool res = FbmUpdateRadioCodes();
    if (res == true) {
      Serial.println("firebase configuration downloaded!");
      boot_sm = 3;
    }
  }

  // firebase monitoring
  if (boot_sm == 3) {
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
        Serial.println("get failed: control");
        Serial.println(Firebase.error());
      } else {
        JsonVariant variant = fbobject.getJsonVariant();
        JsonObject &object = variant.as<JsonObject>();

        if (object.success()) {
          control_alarm = object["alarm"];
          control_radio_learn = object["radio_learn"];
          control_radio_update = object["radio_update"];

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
          Serial.println("set failed: status");
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
          Serial.println("push failed: logs/TH");
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
        // FbmUpdateRadioCodes();
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

    if (control_radio_update == true) {
      // clear request
      Firebase.setBool("control/radio_update", false);
      if (Firebase.failed()) {
        Serial.println("set failed: control/radio_update");
        Serial.println(Firebase.error());
      } else {
        // force update DB
        control_radio_update = false;
        boot_sm = 2;
      }
    }

    // monitor timers
    if (fbm_timer_monitor_cnt >= 15) {
      fbm_timer_monitor_cnt = 0;
      RF_MonitorTimers();
    }

    // monitor for RF radio codes
    uint32_t code = RF_GetRadioCode();
    if (code != 0) {
      if (control_radio_learn == true) {
        // acquire Active Radio Codes from FB
        // FbmUpdateRadioCodes();
        if (code != fbm_code_last) {
          if (RF_CheckRadioCodeDB(code) == false) {
            Serial.printf("RadioCodes/Inactive: %x\n", code);
            yield();
            Firebase.pushInt("RadioCodes/Inactive", code);
            if (Firebase.failed()) {
              Serial.println("set failed: RadioCodes/Inactive");
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
