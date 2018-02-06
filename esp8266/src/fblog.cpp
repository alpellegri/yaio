#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include "firebase.h"
#include "ee.h"
#include "fbconf.h"
#include "fcm.h"
#include "timesrv.h"

void fblog_log(String message, boolean fcm_notify) {
  DynamicJsonBuffer jsonBuffer;
  JsonObject &log = jsonBuffer.createObject();
  String source = EE_GetDomain() + F("/") + EE_GetNodeName();
  String msg = source + F(" ") + message;

  log["time"] = getTime();
  log["source"] = source;
  log["msg"] = message;

  Serial.println(msg);
  if (fcm_notify == true) {
    FcmSendPush(msg);
  }
  String klogs;
  FbSetPath_logs(klogs);
  String data;
  log.printTo(data);
  Firebase.pushJSON((klogs + F("/Reports")), data);
}
