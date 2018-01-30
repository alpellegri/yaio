#include <Arduino.h>
#include <ArduinoJson.h>
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
static const char _kexec[] PROGMEM = "exec";
static const char _kfcmtoken[] PROGMEM = "fcmtoken";
static const char _kdata[] PROGMEM = "data";
static const char _klogs[] PROGMEM = "logs";

void FbSetPath_fcmtoken(String &path){
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  path = prefix_user + String(FPSTR(_kfcmtoken));
}

void FbSetPath_startup(String &path){
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  String nodesubpath = EE_GetDomain() + String(F("/")) + EE_GetNodeName();
  String prefix_node =
      prefix_user + String(F("root/")) + nodesubpath + String(F("/"));
  path = prefix_node + String(FPSTR(_kstartup));
}

void FbSetPath_control(String &path){
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  String nodesubpath = EE_GetDomain() + String(F("/")) + EE_GetNodeName();
  String prefix_node =
      prefix_user + String(F("root/")) + nodesubpath + String(F("/"));
  path = prefix_node + String(FPSTR(_kcontrol));
}

void FbSetPath_status(String &path){
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  String nodesubpath = EE_GetDomain() + String(F("/")) + EE_GetNodeName();
  String prefix_node =
      prefix_user + String(F("root/")) + nodesubpath + String(F("/"));
  path = prefix_node + String(FPSTR(_kstatus));
}

void FbSetPath_exec(String &path){
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  String nodesubpath = EE_GetDomain() + String(F("/")) + EE_GetNodeName();
  String prefix_data = prefix_user + String(F("obj/"));
  path = prefix_data + String(FPSTR(_kexec));
}

void FbSetPath_data(String &path){
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  String nodesubpath = EE_GetDomain() + String(F("/")) + EE_GetNodeName();
  String prefix_data = prefix_user + String(F("obj/"));
  path = prefix_data + String(FPSTR(_kdata));
}

void FbSetPath_logs(String &path){
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  String nodesubpath = EE_GetDomain() + String(F("/")) + EE_GetNodeName();
  String prefix_data = prefix_user + String(F("obj/"));
  path = prefix_data + String(FPSTR(_klogs));
}

void dump_path(void) {
  String path;
  FbSetPath_fcmtoken(path);
  Serial.println(path);
  FbSetPath_startup(path);
  Serial.println(path);
  FbSetPath_control(path);
  Serial.println(path);
  FbSetPath_status(path);
  Serial.println(path);
  FbSetPath_exec(path);
  Serial.println(path);
  FbSetPath_data(path);
  Serial.println(path);
  FbSetPath_logs(path);
  Serial.println(path);
}

bool FbmUpdateRadioCodes(void) {
  bool ret = true;

  String nodesubpath = EE_GetDomain() + String(F("/")) + EE_GetNodeName();
  String path;

  if (ret == true) {
    String kfcmtoken;
    FbSetPath_fcmtoken(kfcmtoken);
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
    String kexec;
    FbSetPath_exec(kexec);
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
        if (nestedObject["owner"] == nodesubpath) {
          FB_addProgDB(i->key, i->value);
        }
      }
    }
  }

  if (ret == true) {
    String kdata;
    FbSetPath_data(kdata);
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
        if (nestedObject["owner"] == nodesubpath) {
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
