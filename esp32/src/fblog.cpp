#include <Arduino.h>
#include <FirebaseArduino.h>

#include <stdio.h>
#include <string.h>

#include "ee.h"
#include "fbconf.h"
#include "fcm.h"
#include "timesrv.h"

void fblog_log(String message, boolean fcm_notify) {
  DynamicJsonBuffer jsonBuffer;
  JsonObject &log = jsonBuffer.createObject();
  String msg = EE_GetDomain() + F(" ") + EE_GetNodeName() + F(" ") + message;

  log["time"] = getTime();
  log["msg"] = msg;

  Serial.println(msg);
  if (fcm_notify == true) {
    FcmSendPush(msg);
  }
  Firebase.push((klogs + F("/Reports")), JsonVariant(log));
}
