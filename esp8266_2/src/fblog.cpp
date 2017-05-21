#include <Arduino.h>
#include <FirebaseArduino.h>

#include <stdio.h>
#include <string.h>

#include "ee.h"
#include "timesrv.h"
#include "fcm.h"

void fblog_log(String& message) {
  DynamicJsonBuffer jsonBuffer;
  JsonObject &log = jsonBuffer.createObject();

  log["time"] = getTime();
  log["msg"] = message;

  Serial.println(message);
  FcmSendPush(message);
  Firebase.push("logs/Reports", JsonVariant(log));
}
