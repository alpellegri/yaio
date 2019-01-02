#include <Arduino.h>
#include <cJSON.h>
#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "ee.h"
#include "fbconf.h"
#include "fcm.h"
#include "firebase.h"
#include "timesrv.h"

void fblog_log(String message, boolean fcm_notify) {
  cJSON *log = cJSON_CreateObject();
  if (log != NULL) {
    cJSON *data;
    data = cJSON_CreateNumber(getTime());
    cJSON_AddItemToObject(log, FPSTR("time"), data);
    data = cJSON_CreateString(EE_GetNode().c_str());
    cJSON_AddItemToObject(log, FPSTR("node"), data);
    data = cJSON_CreateString(EE_GetDomain().c_str());
    cJSON_AddItemToObject(log, FPSTR("domain"), data);
    data = cJSON_CreateString(message.c_str());
    cJSON_AddItemToObject(log, FPSTR("msg"), data);

    String source = EE_GetDomain() + F("/") + EE_GetNode();
    String msg = source + F(" ") + message;

    DEBUG_PRINT("%s\n", msg.c_str());
    if (fcm_notify == true) {
      FcmSendPush(msg);
    }
    String klogs = FbGetPath_message();
    char *string = cJSON_Print(log);
    Firebase.pushJSON(klogs, String(string));
    free(string);
  }
  cJSON_Delete(log);
}
