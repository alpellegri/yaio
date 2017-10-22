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
#include "sta.h"
#include "timesrv.h"
#include "vers.h"

#define DHTPIN D6
#define DHTTYPE DHT22

DHT dht(DHTPIN, DHTTYPE);

static uint8_t boot_sm = 0;
static bool boot_first = false;
static bool status_alarm = false;
static bool status_alarm_last = false;
static bool control_alarm = false;
static bool control_radio_learn = false;
static bool control_radio_update = false;
static uint32_t control_time;
static uint32_t control_time_last;

static uint16_t bootcnt = 0;
static uint32_t fbm_update_last = 0;
static uint32_t fbm_time_th_last = 0;
static uint32_t fbm_monitor_last = 0;
static bool fbm_monitor_run = false;

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

#define FBM_LOGIC_QUEUE_LEN 3
typedef struct {
  uint8_t func;
  uint8_t value;
  uint8_t src_type;
  uint8_t src_idx;
} FbmFuncSrvQueque_t;

static uint8_t FbmLogicQuequeWrPos = 0;
static uint8_t FbmLogicQuequeRdPos = 0;
static FbmFuncSrvQueque_t FbmLogicQueque[FBM_LOGIC_QUEUE_LEN];

void FbmLogicReq(uint8_t src_type, uint8_t src_idx, uint8_t lin, bool value) {
  FbmLogicQueque[FbmLogicQuequeWrPos].src_type = src_type;
  FbmLogicQueque[FbmLogicQuequeWrPos].src_idx = src_idx;
  FbmLogicQueque[FbmLogicQuequeWrPos].func = lin;
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
 * lin=0: value=1 -> arm alarm / value=0 -> disarm alarm
 */
static bool FbmLogicAction(uint32_t src_type, uint32_t src_idx, uint8_t lin,
                           bool value) {
  bool ret = false;
  if (lin == 0) {
    Firebase.setBool(F("control/alarm"), value);
    if (Firebase.failed()) {
    } else {
      ret = true;
    }
  } else if (lin == 1) {
    String str = String(F("Intrusion in: ")) +
                 String(RF_GetRadioName(src_idx)) + String(F(" !!!"));
    fblog_log(str, status_alarm);
    ret = true;
  } else {
    ret = true;
  }

  return ret;
}

void FbmLogicSrv() {
  if (FbmLogicQuequeWrPos != FbmLogicQuequeRdPos) {
    bool ret = FbmLogicAction(FbmLogicQueque[FbmLogicQuequeRdPos].src_type,
                              FbmLogicQueque[FbmLogicQuequeRdPos].src_idx,
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

bool FbmUpdateRadioCodes(void) {
  bool ret = true;
  yield();

  if (ret == true) {
    FirebaseObject ref = Firebase.get(F("FCM_Registration_IDs"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: FCM_Registration_IDs"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      FcmResetRegIDsDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject &nestedObject = i->value;
        String id = i->value.asString();
        Serial.println(id);
        FcmAddRegIDsDB(id);
      }
    }
  }

  if (ret == true) {
    Serial.println(F("FbmUpdateRadioCodes Rx"));
    FirebaseObject ref = Firebase.get(F("RadioCodes/Active"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: RadioCodes/Active"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_DeInitRadioCodeDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }
      RF_InitRadioCodeDB(num);
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject &nestedObject = i->value;
        String id = nestedObject["id"];
        String name = nestedObject["name"];
        String func = nestedObject["func"];
        Serial.println(id);
        RF_AddRadioCodeDB(id, name, func);
      }
    }
  }

  if (ret == true) {
    Serial.println(F("FbmUpdateRadioCodes Tx"));
    FirebaseObject ref = Firebase.get(F("RadioCodes/ActiveTx"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: RadioCodes/ActiveTx"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_DeInitRadioCodeTxDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }
      RF_InitRadioCodeTxDB(num);
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
    Serial.println(F("FbmUpdateRadioCodes Timers"));
    FirebaseObject ref = Firebase.get(F("Timers"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: Timers"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_DeInitTimerDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }
      RF_InitTimerDB(num);
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
    Serial.println(F("FbmUpdateDIO Dout"));
    FirebaseObject ref = Firebase.get(F("DIO/Dout"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: DIO/Dout"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_DeInitDoutDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }
      RF_InitDoutDB(num);
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

  if (ret == true) {
    Serial.println(F("FbmUpdateLIO Lout"));
    FirebaseObject ref = Firebase.get(F("LIO/Lout"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: LIO/Lout"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_DeInitLoutDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }
      RF_InitLoutDB(num);
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject &nestedObject = i->value;
        String id = nestedObject["id"];
        Serial.println(id);
        RF_AddLoutDB(id);
      }
    }
  }

  if (ret == true) {
    Serial.println(F("FbmUpdateFuncions"));
    FirebaseObject ref = Firebase.get(F("Functions"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: Funcions"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_DeInitFunctionsDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }
      RF_InitFunctionsDB(num);
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject &nestedObject = i->value;
        String name = nestedObject["name"];
        String type = nestedObject["type"];
        String action = nestedObject["action"];
        String delay = nestedObject["delay"];
        String next = nestedObject["next"];
        Serial.println(name);
        RF_AddFunctionsDB(name, type, action, delay, next);
      }
    }
  }

  return ret;
}

/* main function task */
bool FbmService(void) {
  bool ret = false;

  switch (boot_sm) {
  // firebase init
  case 0: {
    bool ret = true;
    char *firebase_url = NULL;
    char *firebase_secret = NULL;

    firebase_url = EE_GetFirebaseUrl();
    firebase_secret = EE_GetFirebaseSecret();
    Firebase.begin(firebase_url, firebase_secret);
    yield();
    Firebase.setInt(F("control/reboot"), 0);
    if (Firebase.failed()) {
      Serial.print(F("set failed: control/reboot"));
      Serial.println(Firebase.error());
    } else {
      Serial.println(F("firebase: connected!"));
      boot_sm = 1;
    }
    yield();
  } break;

  // firebase control/status init
  case 1: {
    FirebaseObject fbobject = Firebase.get(F("startup"));
    if (Firebase.failed()) {
      Serial.println(F("set failed: status/bootcnt"));
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
        Firebase.set(F("startup"), JsonVariant(object));
        if (Firebase.failed()) {
          bootcnt--;
          Serial.println(F("set failed: status/bootcnt"));
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
        String str = String(ESP.getResetReason());
        fblog_log(str, true);
      }

      Serial.println(F("Node is up!"));
      // trick
      RF_ForceDisable();
      status_alarm = false;
      control_time_last = 0;
      boot_sm = 3;
    }
  } break;

  // firebase monitoring
  case 3: {
    uint32_t time_now = getTime();
    if ((time_now - fbm_update_last) >=
        ((fbm_monitor_run == true) ? (1) : (5))) {
      Serial.print(F("boot_sm "));
      Serial.print(boot_sm);
      Serial.print(F(": heap "));
      Serial.println(ESP.getFreeHeap());
      fbm_update_last = time_now;

      float h = dht.readHumidity();
      float t = dht.readTemperature();
      if (isnan(h) || isnan(t)) {
        // Serial.println(F("Failed to read from DHT sensor!"));
      } else {
        humidity_data = h;
        temperature_data = t;
      }
      yield();

      control_time = Firebase.getInt(F("control/time"));
      if (Firebase.failed() == true) {
        Serial.print(F("get failed: control/time"));
        Serial.println(Firebase.error());
      } else {
        if (control_time != control_time_last) {
          control_time_last = control_time;
          fbm_monitor_last = time_now;
          fbm_monitor_run = true;
        }
        if (fbm_monitor_run == true) {
          if ((time_now - fbm_monitor_last) > 5) {
            fbm_monitor_run = false;
          }

          FirebaseObject fbobject = Firebase.get(F("control"));
          if (Firebase.failed() == true) {
            Serial.println(F("get failed: control"));
            Serial.print(Firebase.error());
          } else {
            JsonVariant variant = fbobject.getJsonVariant();
            JsonObject &object = variant.as<JsonObject>();
            if (object.success()) {
              control_alarm = object["alarm"];
              control_radio_learn = object["radio_learn"];
              control_radio_update = object["radio_update"];
              control_time = object["time"];

              bool control_wol = object["wol"];
              if (control_wol == true) {
                Serial.println(F("Sending WOL Packet..."));
                sendWOL(computer_ip, mac, sizeof mac);
              }

              int control_reboot = object["reboot"];
              if (control_reboot == 2) {
                boot_sm = 4;
              } else if (control_reboot == 1) {
                ESP.restart();
              }
            } else {
              Serial.println(F("parseObject() failed"));
            }
          }

          Serial.printf("control_monitor %d, %d\n", time_now, fbm_monitor_last);

          DynamicJsonBuffer jsonBuffer;
          JsonObject &status = jsonBuffer.createObject();
          status["alarm"] = status_alarm;
          status["monitor"] = fbm_monitor_run;
          status["heap"] = ESP.getFreeHeap();
          status["humidity"] = humidity_data;
          status["temperature"] = temperature_data;
          status["time"] = time_now;
          yield();
          Firebase.set(F("status"), JsonVariant(status));
          if (Firebase.failed()) {
            Serial.print(F("set failed: status"));
            Serial.println(Firebase.error());
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
        Firebase.push(F("logs/TH"), JsonVariant(th));
        if (Firebase.failed()) {
          Serial.print(F("push failed: logs/TH"));
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

    // manage alarm arming/disarming notifications
    if (status_alarm_last != status_alarm) {
      status_alarm_last = status_alarm;
      String str = F("Alarm ");
      str += String((status_alarm == true) ? ("active") : ("inactive"));
      fblog_log(str, false);
      yield();
    }

    if (control_radio_update == true) {
      // clear request
      Firebase.setBool(F("control/radio_update"), false);
      if (Firebase.failed()) {
        Serial.print(F("set failed: control/radio_update"));
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
      uint8_t idx = RF_CheckRadioCodeDB(code);
      if (idx != 0xFF) {
        fbm_monitor_last = time_now;
        fbm_monitor_run = true;
        // RF found in Rx DB, make an action
        RF_ExecuteRadioCodeDB(idx);
      }

      // acquire Active Radio Codes from FB
      if (idx == 0xFF) {
        fbm_monitor_last = time_now;
        fbm_monitor_run = true;
        uint32_t idxTx = RF_CheckRadioCodeTxDB(code);
        if (idxTx == 0xFF) {
          Serial.print(F("RadioCodes/Inactive: "));
          Serial.println(code);
          yield();
          Firebase.setInt(F("RadioCodes/Inactive/last/id"), code);
          if (Firebase.failed()) {
            Serial.print(F("set failed: RadioCodes/Inactive"));
            Serial.println(Firebase.error());
          } else {
          }
        }
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
