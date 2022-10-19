#include <Arduino.h>
#include <ArduinoJson.h>

#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "ee.h"
#include "fbconf.h"
#include "fbutils.h"
#include "fcm.h"
#include "firebase.h"
#include "pht.h"
#include "rf.h"

static const char _kstartup[] PROGMEM = "startup";
static const char _kcontrol[] PROGMEM = "control";
static const char _kstatus[] PROGMEM = "status";
static const char _kexec[] PROGMEM = "exec";
static const char _kfcmtoken[] PROGMEM = "fcmtoken";
static const char _kdata[] PROGMEM = "data";
static const char _kmessages[] PROGMEM = "messages";
static const char _klogs[] PROGMEM = "logs";

String FbGetPath_fcmtoken(void) {
  String path;
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  path = prefix_user + String(FPSTR(_kfcmtoken));
  return path;
}

String FbGetPath_startup(void) {
  String path;
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  String nodesubpath = EE_GetDomain() + String(F("/")) + EE_GetNode();
  String prefix_node =
      prefix_user + String(F("root/")) + nodesubpath + String(F("/"));
  path = prefix_node + String(FPSTR(_kstartup));
  return path;
}

String FbGetPath_control(void) {
  String path;
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  String nodesubpath = EE_GetDomain() + String(F("/")) + EE_GetNode();
  String prefix_node =
      prefix_user + String(F("root/")) + nodesubpath + String(F("/"));
  path = prefix_node + String(FPSTR(_kcontrol));
  return path;
}

String FbGetPath_status(void) {
  String path;
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  String nodesubpath = EE_GetDomain() + String(F("/")) + EE_GetNode();
  String prefix_node =
      prefix_user + String(F("root/")) + nodesubpath + String(F("/"));
  path = prefix_node + String(FPSTR(_kstatus));
  return path;
}

String FbGetPath_exec(void) {
  String path;
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  String subpath = EE_GetDomain() + String(F("/")) + EE_GetNode();
  String prefix_data = prefix_user + String(F("obj/"));
  path = prefix_data + String(FPSTR(_kexec)) + String(F("/")) + subpath;
  return path;
}

String FbGetPath_data(void) {
  String path;
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  String subpath = EE_GetDomain();
  String prefix_data = prefix_user + String(F("obj/"));
  path = prefix_data + String(FPSTR(_kdata)) + String(F("/")) + subpath;
  return path;
}

String FbGetPath_message(void) {
  String path;
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  String subpath = EE_GetDomain();
  String prefix_data = prefix_user + String(F("obj/"));
  path = prefix_data + String(FPSTR(_kmessages));
  return path;
}

String FbGetPath_log(void) {
  String path;
  String prefix_user = String(F("users/")) + EE_GetUID() + String(F("/"));
  String subpath = EE_GetDomain();
  String prefix_data = prefix_user + String(F("obj/"));
  path = prefix_data + String(FPSTR(_klogs)) + String(F("/")) + subpath;
  return path;
}

void dump_path(void) {
  String path;
  path = FbGetPath_fcmtoken();
  DEBUG_PRINT("%s\n", path.c_str());
  path = FbGetPath_startup();
  DEBUG_PRINT("%s\n", path.c_str());
  path = FbGetPath_control();
  DEBUG_PRINT("%s\n", path.c_str());
  path = FbGetPath_status();
  DEBUG_PRINT("%s\n", path.c_str());
  path = FbGetPath_exec();
  DEBUG_PRINT("%s\n", path.c_str());
  path = FbGetPath_data();
  DEBUG_PRINT("%s\n", path.c_str());
  path = FbGetPath_message();
  DEBUG_PRINT("%s\n", path.c_str());
  path = FbGetPath_log();
  DEBUG_PRINT("%s\n", path.c_str());
}

bool FbGetDB(void) {
  bool ret = true;

  String owner = EE_GetNode();
  String path;

  if (ret == true) {
    String data = FbGetPath_fcmtoken();
    DEBUG_PRINT("path: %s\n", data.c_str());
    String json = Firebase.getJSON(data);
    if (Firebase.failed() == true) {
      DEBUG_PRINT("get failed: %s\n", data.c_str());
      DEBUG_PRINT("%s\n", Firebase.error().c_str());
      ret = false;
    } else {
      FB_deinitRegIDsDB();
      DynamicJsonDocument doc(1024);
      auto error = deserializeJson(doc, json);
      if (!error) {
        JsonObject object = doc.as<JsonObject>();
        for (JsonPair p : object) {
          TokenEntry token;
          token.key = p.key().c_str();
          token.value = p.value().as<String>();
          FB_addRegIDsDB(token);
        }
      } else {
        DEBUG_PRINT("deserializeJson error: %s\n", data.c_str());
      }
    }
  }

  if (ret == true) {
    String data = FbGetPath_exec();
    DEBUG_PRINT("path: %s\n", data.c_str());
    String json = Firebase.getJSON(data);
    if (Firebase.failed() == true) {
      DEBUG_PRINT("get failed: %s\n", data.c_str());
      DEBUG_PRINT("%s\n", Firebase.error().c_str());
      ret = false;
    } else {
      FB_deinitProgDB();
      DynamicJsonDocument doc(16384);
      auto error = deserializeJson(doc, json);
      if (!error) {
        JsonObject object = doc.as<JsonObject>();
        for (JsonPair p : object) {
          String key = p.key().c_str();
          JsonObject value = p.value().as<JsonObject>();
          FB_addProgDB(key, value);
        }
      } else {
        DEBUG_PRINT("deserializeJson error: %s\n", data.c_str());
      }
    }
  }

  if (ret == true) {
    String data = FbGetPath_data();
    DEBUG_PRINT("path: %s\n", data.c_str());
    String json = Firebase.getJSON(data);
    if (Firebase.failed() == true) {
      DEBUG_PRINT("get failed: %s\n", data.c_str());
      DEBUG_PRINT("%s\n", Firebase.error().c_str());
      ret = false;
    } else {
      PHT_Deinit();
      FB_deinitIoEntryDB();
      DynamicJsonDocument doc(16384);
      auto error = deserializeJson(doc, json);
      if (!error) {
        JsonObject object = doc.as<JsonObject>();
        for (JsonPair p : object) {
          String key = p.key().c_str();
          JsonObject value = p.value().as<JsonObject>();
          if (value[F("owner")] == owner) {
            FB_addIoEntryDB(key, value);
          }
        }
      } else {
        DEBUG_PRINT("deserializeJson error: %s\n", data.c_str());
      }
    }
  }

  FB_dumpIoEntry();
  FB_dumpProg();

  return ret;
}
