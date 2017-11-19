#include <Arduino.h>
#include <FirebaseArduino.h>

#include <stdio.h>
#include <string.h>

#include "fbconf.h"
#include "fcm.h"
#include "rf.h"

#define kDOut 0
#define kRadioIn 1
#define kLOut 2
#define kDIn 3
#define kRadioOut 4
#define kRadioElem 5

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
        JsonObject &nestedObject = i->value;
        String key = i->key;
        String type = nestedObject["type"];
        String action = nestedObject["action"];
        uint32_t delay = nestedObject["delay"];
        String next = nestedObject["next"];
        Serial.println(key);
        RF_AddFunctionsDB(key, type, action, delay, next);
      }
    }
  }

  if (ret == true) {
    Serial.println(F("graph"));
    FirebaseObject ref = Firebase.get(F("graph"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: graph"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_DeInitRadioCodeDB();
      RF_DeInitRadioCodeTxDB();
      RF_DeInitDoutDB();
      RF_DeInitLoutDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t numRx = 0;
      uint8_t numTx = 0;
      uint8_t numDout = 0;
      uint8_t numLout = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        JsonObject &nestedObject = i->value;
        String id = nestedObject["id"];
        uint8_t type = nestedObject["type"];
        Serial.printf("%s, %d\n", id.c_str(), type);
        switch (type) {
        case kDOut:
          numDout++;
          break;
        case kRadioIn:
          numRx++;
          break;
        case kLOut:
          numLout++;
          break;
        case kRadioOut:
          numTx++;
          break;
        default:
          break;
        }
      }
      Serial.printf("%d, %d, %d, %d\n", numDout, numRx, numLout, numTx);

      RF_InitRadioCodeDB(numRx);
      RF_InitRadioCodeTxDB(numTx);
      RF_InitDoutDB(numDout);
      RF_InitLoutDB(numLout);
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        JsonObject &nestedObject = i->value;
        String name = nestedObject["name"];
        String id = nestedObject["id"];
        uint8_t type = nestedObject["type"];
        String func = nestedObject["func"];
        Serial.printf("name %s\n", name.c_str());
        Serial.printf("id %s\n", id.c_str());
        Serial.printf("type %d\n", type);
        Serial.printf("func %s\n", func.c_str());
        switch (type) {
        case kDOut:
          RF_AddDoutDB(id);
          break;
        case kRadioIn:
          RF_AddRadioCodeDB(id, name, func);
          break;
        case kLOut:
          RF_AddLoutDB(id);
          break;
        case kRadioOut:
          RF_AddRadioCodeTxDB(id);
          break;
        default:
          break;
        }
      }
    }
  }

  return ret;
}
