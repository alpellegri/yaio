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

#define DEBUG_PRINT(fmt, ...) Serial.printf_P(PSTR(fmt), ##__VA_ARGS__)

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
  DEBUG_PRINT("%s\n", path.c_str());
  FbSetPath_startup(path);
  DEBUG_PRINT("%s\n", path.c_str());
  FbSetPath_control(path);
  DEBUG_PRINT("%s\n", path.c_str());
  FbSetPath_status(path);
  DEBUG_PRINT("%s\n", path.c_str());
  FbSetPath_exec(path);
  DEBUG_PRINT("%s\n", path.c_str());
  FbSetPath_data(path);
  DEBUG_PRINT("%s\n", path.c_str());
  FbSetPath_logs(path);
  DEBUG_PRINT("%s\n", path.c_str());
}

bool FbmUpdateRadioCodes(void) {
  bool ret = true;

  String nodesubpath = EE_GetDomain() + String(F("/")) + EE_GetNodeName();
  String path;

  if (ret == true) {
    String kfcmtoken;
    FbSetPath_fcmtoken(kfcmtoken);
    DEBUG_PRINT("%s\n", kfcmtoken.c_str());
    FirebaseObject ref = Firebase.get(kfcmtoken);
    if (Firebase.failed() == true) {
      DEBUG_PRINT("get failed: kfcmtoken");
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
    DEBUG_PRINT("%s\n", kexec.c_str());
    FirebaseObject ref = Firebase.get(kexec);
    if (Firebase.failed() == true) {
      DEBUG_PRINT("get failed: kexec");
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
    DEBUG_PRINT("%s\n", kdata.c_str());
    FirebaseObject ref = Firebase.get(kdata);
    if (Firebase.failed() == true) {
      DEBUG_PRINT("get failed: kdata");
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
  FB_dumpProg();

  return ret;
}
