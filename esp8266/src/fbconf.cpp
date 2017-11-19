#include <Arduino.h>
#include <FirebaseArduino.h>

#include <stdio.h>
#include <string.h>

#include "fbconf.h"
#include "fcm.h"
#include "rf.h"

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
    Serial.println(F("FbmUpdateFuncions"));
    FirebaseObject ref = Firebase.get(F("Functions"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: Funcions"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_deinitFunctionDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }
      RF_initFunctionDB(num);
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        JsonObject &nestedObject = i->value;
        String key = i->key;
        String type = nestedObject["type"];
        String action = nestedObject["action"];
        uint32_t delay = nestedObject["delay"];
        String next = nestedObject["next"];
        RF_addFunctionDB(key, type, action, delay, next);
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
      RF_deinitIoEntryDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }

      RF_initIoEntryDB(num);
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        JsonObject &nestedObject = i->value;
        String key = i->key;
        String name = nestedObject["name"];
        String id = nestedObject["id"];
        uint8_t type = nestedObject["type"];
        String func = nestedObject["func"];
        RF_addIoEntryDB(key, type, id, name, func);
      }
    }
  }

  // RF_dumpIoEntry();

  return ret;
}
