#include <Arduino.h>
#include <ArduinoJson.h>

#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "ee.h"
#include "fbconf.h"
#include "fcm.h"
#include "firebase.h"
#include "timesrv.h"

void fblog_log(String message, boolean fcm_notify) {
  DynamicJsonBuffer jsonBuffer;
  JsonObject &log = jsonBuffer.createObject();

  log[F("time")] = getTime();
  log[F("node")] = EE_GetNode();
  log[F("domain")] = EE_GetDomain();
  log[F("msg")] = message;

  String source = EE_GetDomain() + F("/") + EE_GetNode();
  String msg = source + F(" ") + message;

  DEBUG_PRINT("%s\n", msg.c_str());
  if (fcm_notify == true) {
    FcmSendPush(msg);
  }
  String klogs;
  FbSetPath_message(klogs);
  String data;
  log.printTo(data);
  Firebase.pushJSON(klogs, data);
}
