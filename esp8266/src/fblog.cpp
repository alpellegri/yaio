#include <Arduino.h>
#include <FirebaseArduino.h>

#include <stdio.h>
#include <string.h>

#include "ee.h"
#include "fcm.h"
#include "timesrv.h"

void fblog_log(String message, boolean fcm_notify) {
  DynamicJsonBuffer jsonBuffer;
  JsonObject &log = jsonBuffer.createObject();

  log["time"] = getTime();
  log["msg"] = message;

  Serial.println(message);
  if (fcm_notify == true) {
    FcmSendPush(message);
  }
  Firebase.push(F("logs/Reports"), JsonVariant(log));
}
