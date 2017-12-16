#include <Arduino.h>
#include <FirebaseArduino.h>

#include <stdio.h>
#include <string.h>

#include "ee.h"
#include "fbconf.h"
#include "fcm.h"
#include "rf.h"

String kstartup = "startup";
String kcontrol = "control";
String kstatus = "status";
String kfunctions = "Functions";
String kmessaging = "FCM_Registration_IDs";
String kgraph = "graph";
String klogs = "logs";

void FbconfInit(void) {
  String prefix = "users/" + EE_GetUID() + "/" + EE_GetDomain() + "/" +
                  EE_GetNodeName() + "/";

  kstartup = prefix + kstartup;
  kcontrol = prefix + kcontrol;
  kstatus = prefix + kstatus;
  kfunctions = prefix + kfunctions;
  kmessaging = prefix + kmessaging;
  kgraph = prefix + kgraph;
  klogs = prefix + klogs;
  Serial.println(kstartup);
  Serial.println(kcontrol);
  Serial.println(kstatus);
  Serial.println(kfunctions);
  Serial.println(kmessaging);
  Serial.println(kgraph);
  Serial.println(klogs);
}

bool FbmUpdateRadioCodes(void) {
  bool ret = true;
  yield();

  if (ret == true) {
    Serial.println(kmessaging);
    FirebaseObject ref = Firebase.get(kmessaging);
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: kmessaging"));
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
    Serial.println(kfunctions);
    FirebaseObject ref = Firebase.get(kfunctions);
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: kfunctions"));
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
    Serial.println(kgraph);
    FirebaseObject ref = Firebase.get(kgraph);
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: kgraph"));
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

  RF_dumpIoEntry();

  return ret;
}
