#include <Arduino.h>
#include <FirebaseArduino.h>

#include <stdio.h>
#include <string.h>

#include "ee.h"
#include "fbconf.h"
#include "fbutils.h"
#include "fcm.h"
#include "rf.h"

static const char _kstartup[] PROGMEM = "startup";
static const char _kcontrol[] PROGMEM = "control";
static const char _kstatus[] PROGMEM = "status";
static const char _kfunctions[] PROGMEM = "Functions";
static const char _kmessaging[] PROGMEM = "fcmtoken";
static const char _kgraph[] PROGMEM = "graph";
static const char _klogs[] PROGMEM = "logs";

String kstartup;
String kcontrol;
String kstatus;
String kfunctions;
String kmessaging;
String kgraph;
String klogs;
String knodesubpath;

String FB_getNodeSubPath(void) { return knodesubpath; }

void FbconfInit(void) {
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  knodesubpath = EE_GetDomain() + String(F("/")) + EE_GetNodeName();
  String prefix_node =
      prefix_user + String(F("root/")) + knodesubpath + String(F("/"));
  String prefix_data = prefix_user + String(F("data/"));

  kmessaging = prefix_user + String(FPSTR(_kmessaging));

  kstartup = prefix_node + String(FPSTR(_kstartup));
  kcontrol = prefix_node + String(FPSTR(_kcontrol));
  kstatus = prefix_node + String(FPSTR(_kstatus));

  kfunctions = prefix_data + String(FPSTR(_kfunctions));
  kgraph = prefix_data + String(FPSTR(_kgraph));
  klogs = prefix_data + String(FPSTR(_klogs));
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
      FB_deinitFunctionDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        JsonObject &nestedObject = i->value;
        if (nestedObject["owner"] == FB_getNodeSubPath()) {
          num++;
        }
      }

      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        JsonObject &nestedObject = i->value;
        if (nestedObject["owner"] == FB_getNodeSubPath()) {
          String key = i->key;
          uint8_t code = nestedObject["code"];
          String value = nestedObject["value"];
          String cb = nestedObject["cb"];
          FB_addFunctionDB(key, code, value, 0, cb);
        }
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
      FB_deinitIoEntryDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        JsonObject &nestedObject = i->value;
        if (nestedObject["owner"] == FB_getNodeSubPath()) {
          num++;
        }
      }

      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        JsonObject &nestedObject = i->value;
        if (nestedObject["owner"] == FB_getNodeSubPath()) {
          String key = i->key;
          String name = nestedObject["name"];
          uint8_t code = nestedObject["code"];
          String value = nestedObject["value"];
          String cb = nestedObject["func"];
          FB_addIoEntryDB(key, code, value, name, cb);
        }
      }
    }
  }

  FB_dumpIoEntry();
  FB_dumpFunctions();

  return ret;
}
