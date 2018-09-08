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

  log["time"] = getTime();
  log["source"] = EE_GetNodeName();
  log["msg"] = message;

  String source = EE_GetDomain() + F("/") + EE_GetNodeName();
  String msg = source + F(" ") + message;

  Serial.println(msg);
  if (fcm_notify == true) {
    FcmSendPush(msg);
  }
  String klogs;
  FbSetPath_message(klogs);
  String data;
  log.printTo(data);
  Firebase.pushJSON(klogs, data);
}
