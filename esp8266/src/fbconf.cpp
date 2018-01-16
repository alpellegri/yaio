#include <Arduino.h>
#include <FirebaseArduino.h>
#include <ArduinoJson.h>

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
static const char _kexec[] PROGMEM = "exec";
static const char _kfcmtoken[] PROGMEM = "fcmtoken";
static const char _kdata[] PROGMEM = "data";
static const char _klogs[] PROGMEM = "logs";

String kstartup;
String kcontrol;
String kstatus;
String kexec;
String kfcmtoken;
String kdata;
String klogs;
String knodesubpath;

String FB_getNodeSubPath(void) { return knodesubpath; }

void FbconfInit(void) {
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  knodesubpath = EE_GetDomain() + String(F("/")) + EE_GetNodeName();
  String prefix_node =
      prefix_user + String(F("root/")) + knodesubpath + String(F("/"));
  String prefix_data = prefix_user + String(F("obj/"));

  kfcmtoken = prefix_user + String(FPSTR(_kfcmtoken));

  kstartup = prefix_node + String(FPSTR(_kstartup));
  kcontrol = prefix_node + String(FPSTR(_kcontrol));
  kstatus = prefix_node + String(FPSTR(_kstatus));

  kexec = prefix_data + String(FPSTR(_kexec));
  kdata = prefix_data + String(FPSTR(_kdata));
  klogs = prefix_data + String(FPSTR(_klogs));
  Serial.println(kstartup);
  Serial.println(kcontrol);
  Serial.println(kstatus);
  Serial.println(kfcmtoken);
  Serial.println(kexec);
  Serial.println(kdata);
  Serial.println(klogs);
}

bool FbmUpdateRadioCodes(void) {
  bool ret = true;
  yield();

  if (ret == true) {
    Serial.println(kfcmtoken);
    FirebaseObject ref = Firebase.get(kfcmtoken);
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: kfcmtoken"));
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
    Serial.println(kexec);
    FirebaseObject ref = Firebase.get(kexec);
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: kexec"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      FB_deinitProgDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();

      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        JsonObject &nestedObject = i->value;
        if (nestedObject["owner"] == FB_getNodeSubPath()) {
          FB_addProgDB(i->key, i->value);
        }
      }
    }
  }

  if (ret == true) {
    Serial.println(kdata);
    FirebaseObject ref = Firebase.get(kdata);
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: kdata"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      FB_deinitIoEntryDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();

      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        JsonObject &nestedObject = i->value;
        if (nestedObject["owner"] == FB_getNodeSubPath()) {
          String key = i->key;
          String name = nestedObject["name"];
          uint8_t code = nestedObject["code"];
          String value = nestedObject["value"];
          String cb = nestedObject["cb"];
          FB_addIoEntryDB(key, name, code, value, cb);
        }
      }
    }
  }

  FB_dumpIoEntry();
  // FB_dumpFunctions();
  FB_dumpProg();

  return ret;
}
