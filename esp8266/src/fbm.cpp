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
bool control_monitor_last = false;

uint16_t bootcnt = 0;
uint32_t fbm_code_last = 0;
time_t fbm_update_last = 0;
time_t fbm_time_th_last = 0;
time_t fbm_stop_monitor_time = 0;
bool fbm_monitor_run = false;

uint32_t humidity_data;
uint32_t temperature_data;

time_t fbm_update_timer_last;

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
  udp.beginPacket(addr, 8889);
  udp.write(preamble, sizeof preamble);
  for (i = 0; i < 16; i++) {
    udp.write(mac, size_of_mac);
  }

  udp.endPacket();
  yield();
}

bool FbmUpdateRadioCodes(void) {
  bool ret = true;
  yield();

  if (ret == true) {
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
        JsonObject &nestedObject = i->value;
        String type = nestedObject["type"];
        String action = nestedObject["action"];
        String action_d = nestedObject["action_d"];
        String delay = nestedObject["delay"];
        String id = nestedObject["id"];
        Serial.println(id);
        RF_AddRadioCodeDB(id, type, action, delay, action_d);
      }
    }
  }

  if (ret == true) {
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
        JsonObject &nestedObject = i->value;
        String id = nestedObject["id"];
        Serial.println(id);
        RF_AddRadioCodeTxDB(id);
      }
    }
  }

  if (ret == true) {
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
        JsonObject &nestedObject = i->value;
        String type = nestedObject["type"];
        String action = nestedObject["action"];
        String hour = nestedObject["hour"];
        String minute = nestedObject["minute"];
        Serial.println(action);
        RF_AddTimerDB(type, action, hour, minute);
      }
    }
  }

  if (ret == true) {
    Serial.printf("FbmUpdateDIO Dout\n");
    FirebaseObject ref = Firebase.get("DIO/Dout");
    if (Firebase.failed() == true) {
      Serial.print("get failed: DIO/Dout");
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_ResetDoutDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject &nestedObject = i->value;
        String id = nestedObject["id"];
        Serial.println(id);
        RF_AddDoutDB(id);
      }
    }
  }

  return ret;
}

/* main function task */
bool FbmService(void) {
  bool ret = false;

  // Serial.printf("boot_sm: %d, status_alarm: %d, control_alarm: %d,
  // control_radio_learn: %d\n", boot_sm, status_alarm, control_alarm
  // ,control_radio_learn);
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
          Serial.println("firebase: configured!");
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
      Serial.println("Node is up!");
      boot_sm = 3;
    }
  }

  // firebase monitoring
  if (boot_sm == 3) {

    // monitor
    time_t time_now = getTime();
    if ((time_now - fbm_update_last) >= 5) {
      Serial.printf("FbmService - monitor: heap %d\n", ESP.getFreeHeap());
      fbm_update_last = time_now;

      float h = dht.readHumidity();
      float t = dht.readTemperature();
      if (isnan(h) || isnan(t)) {
        // Serial.println("Failed to read from DHT sensor!");
      } else {
        humidity_data = 10 * h;
        temperature_data = 10 * t;
      }
      yield();

      control_monitor = Firebase.getBool("control/monitor");
      if (Firebase.failed() == true) {
        Serial.println("get failed: control/monitor");
        Serial.println(Firebase.error());
      } else {
        if (control_monitor != control_monitor_last) {
          control_monitor_last = control_monitor;
          if (control_monitor == true) {
            fbm_stop_monitor_time = time_now + 10;
            fbm_monitor_run = true;
          }
        }
        if (control_monitor == true) {
          FirebaseObject fbobject = Firebase.get("control");
          if (Firebase.failed() == true) {
            Serial.println("get failed: control");
            Serial.println(Firebase.error());
          } else {
            JsonVariant variant = fbobject.getJsonVariant();
            JsonObject &object = variant.as<JsonObject>();
            if (object.success()) {
              control_alarm = object["alarm"];
              control_radio_learn = object["radio_learn"];
              control_radio_update = object["radio_update"];
              control_monitor = object["monitor"];

              bool control_wol = object["wol"];
              if (control_wol == true) {
                Serial.println("Sending WOL Packet...");
                sendWOL(computer_ip, mac, sizeof mac);
              }

              bool control_reboot = object["reboot"];
              if (control_reboot == true) {
                ESP.restart();
              }
            } else {
              Serial.println("parseObject() failed");
            }
          }

          if (control_monitor == true) {
            Serial.printf("control_monitor %d, %d\n", control_monitor,
                          fbm_stop_monitor_time);

            if ((time_now > fbm_stop_monitor_time) &&
                (fbm_monitor_run == true)) {
              Firebase.setBool("control/monitor", false);
              if (Firebase.failed()) {
                Serial.println("control/monitor");
                Serial.println(Firebase.error());
              } else {
                fbm_monitor_run = false;
              }
            }

            DynamicJsonBuffer jsonBuffer;
            JsonObject &status = jsonBuffer.createObject();
            status["alarm"] = status_alarm;
            status["monitor"] = fbm_monitor_run;
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
          }
        }
      }
      yield();

      // log every 30 minutes
      if ((time_now - fbm_time_th_last) > (30 * 60)) {
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
          fbm_time_th_last = time_now;
        }
      } else {
        /* do nothing */
      }
    }

    // monitor for alarm activation
    if (status_alarm != control_alarm) {
      status_alarm = control_alarm;
      if (status_alarm == true) {
      }
    }

    // manage RF activation/deactivation
    if ((status_alarm == true) || (control_radio_learn == true)) {
      RF_Enable();
    } else {
      RF_Disable();
    }
    yield();

    // manage alarm activation/deactivation notifications
    if (status_alarm_last != status_alarm) {
      status_alarm_last = status_alarm;
      String str = "Alarm ";
      str += String((status_alarm == true) ? ("active") : ("inactive"));
      fblog_log(str, false);
    }
    yield();

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
    yield();

    // monitor timers, every 15 sec
    if ((time_now - fbm_update_timer_last) >= 15) {
      fbm_update_timer_last = time_now;
      RF_MonitorTimers();
    }
    yield();

    // monitor for RF radio codes
    uint32_t code = RF_GetRadioCode();
    if (code != 0) {
      uint32_t idx = RF_CheckRadioCodeDB(code);
      if (idx != 0xFF) {
        String str = String("Intrusion ") + String(code) + String(" !!!");
        fblog_log(str, status_alarm);
      }

      if (control_radio_learn == true) {
        // acquire Active Radio Codes from FB
        if (code != fbm_code_last) {
          if (idx == 0) {
            uint32_t idxTx = RF_CheckRadioCodeTxDB(code);
            if (idxTx == 0) {
              Serial.printf("RadioCodes/Inactive: %x\n", code);
              yield();
              Firebase.pushInt("RadioCodes/Inactive", code);
              if (Firebase.failed()) {
                Serial.println("set failed: RadioCodes/Inactive");
                Serial.println(Firebase.error());
              } else {
                fbm_code_last = code;
                boot_sm = 2;
              }
            }
          }
        }
      }
    }
  }

  return ret;
}
