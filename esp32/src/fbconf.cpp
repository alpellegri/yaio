#include <Arduino.h>
#include <cJSON.h>
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

  if (ret == true) {
    String kfcmtoken = FbGetPath_fcmtoken();
    DEBUG_PRINT("token path: %s\n", kfcmtoken.c_str());
    String json = Firebase.getJSON(kfcmtoken);
    if (Firebase.failed() == true) {
      DEBUG_PRINT("get failed: kfcmtoken\n");
      DEBUG_PRINT("%s\n", Firebase.error().c_str());
      ret = false;
    } else {
      FB_deinitRegIDsDB();
      cJSON *tokens = cJSON_Parse(json.c_str());
      cJSON *item = NULL;
      cJSON_ArrayForEach(item, tokens) {
        char *key = item->string;
        char *value = item->valuestring;
        if ((key != NULL) && (value != NULL)) {
          FB_addRegIDsDB(value);
        }
      }
      cJSON_Delete(tokens);
    }
  }

  if (ret == true) {
    String kexec = FbGetPath_exec();
    DEBUG_PRINT("exex path: %s\n", kexec.c_str());
    String json = Firebase.getJSON(kexec);
    if (Firebase.failed() == true) {
      DEBUG_PRINT("get failed: kexec\n");
      DEBUG_PRINT("%s\n", Firebase.error().c_str());
      ret = false;
    } else {
      FB_deinitProgDB();
      cJSON *exec = cJSON_Parse(json.c_str());
      cJSON *item = NULL;
      cJSON_ArrayForEach(item, exec) {
        char *key = item->string;
        if (key != NULL) {
          cJSON *value = cJSON_GetObjectItemCaseSensitive(exec, key);
          DEBUG_PRINT("exec item: %s\n", item->string);
          FB_addProgDB(key, value);
        }
      }
      cJSON_Delete(exec);
    }
  }

  if (ret == true) {
    String kdata = FbGetPath_data();
    DEBUG_PRINT("data path: %s\n", kdata.c_str());
    String json = Firebase.getJSON(kdata);
    if (Firebase.failed() == true) {
      DEBUG_PRINT("get failed: kdata\n");
      DEBUG_PRINT("%s\n", Firebase.error().c_str());
      ret = false;
    } else {
      PHT_Deinit();
      FB_deinitIoEntryDB();
      cJSON *data = cJSON_Parse(json.c_str());
      cJSON *item = NULL;
      cJSON_ArrayForEach(item, data) {
        char *key = item->string;
        if (key != NULL) {
          cJSON *value = cJSON_GetObjectItemCaseSensitive(data, key);
          cJSON *_owner =
              cJSON_GetObjectItemCaseSensitive(item, FPSTR("owner"));
          if (strcmp(_owner->valuestring, owner.c_str()) == 0) {
            DEBUG_PRINT("data item: %s\n", item->string);
            FB_addIoEntryDB(key, value);
          }
        }
      }
      cJSON_Delete(data);
    }
  }

  FB_dumpIoEntry();
  FB_dumpProg();

  return ret;
}
