#include <Arduino.h>
#include <ArduinoJson.h>
#if 0
#include <ESP8266HTTPClient.h>
#else
// use weak http connection. i.e. do not close in case of SHA1 finger fails!!!
#include <ESP8266HTTPWeakClient.h>
#define HTTPClient HTTPWeakClient
#endif

#include <string.h>

#include "debug.h"
#include "ee.h"
#include "fcm.h"
#include "firebase.h"

#define FCM_NUM_REGIDS_MAX (5)

static const char FcmServer[] PROGMEM = "fcm.googleapis.com";

// up-to 5 devices
static String RegIDs[FCM_NUM_REGIDS_MAX];
static uint8_t RegIDsLen;

void FcmResetRegIDsDB(void) { RegIDsLen = 0; }

void FcmAddRegIDsDB(String string) {
  if (RegIDsLen < FCM_NUM_REGIDS_MAX) {
    RegIDs[RegIDsLen] = string;
    RegIDsLen++;
  }
}

void FcmSendPush(String &message) {
  if (RegIDsLen > 0) {
    int i;
    String fcm_host = String(FPSTR(FcmServer));
    String fcm_server_key = EE_GetFirebaseServerKey();

    //  DATA='{
    //  "notification": {
    //    "body": "this is a body",
    //    "title": "this is a title"
    //  },
    //  "priority": "high",
    //  "data": {
    //    "click_action": "FLUTTER_NOTIFICATION_CLICK",
    //    "id": "1",
    //    "status": "done"
    //  },
    //  "to": "<FCM TOKEN>"}'
    //
    //  curl https://fcm.googleapis.com/fcm/send -H
    //  "Content-Type:application/json" -X POST -d "$DATA" -H "Authorization:
    //  key=<FCM SERVER KEY>"

    /* json data: the notification message multiple devices */
    String json;
    json = F("{");
    json += F("\"notification\":{");
    json += F("\"title\":\"Yaio\",");
    json += F("\"body\":\"");
    json += message;
    json += F("\",");
    json += F("\"sound\":\"default\"");
    json += F("},");

    json += F("\"data\":{");
    json += F("\"click_action\":\"FLUTTER_NOTIFICATION_CLICK\",");
    json += F("\"id\":\"1\",");
    json += F("\"status\":\"done\",");
    json += F("},");

    json += F("\"registration_ids\":[");
    for (i = 0; i < RegIDsLen - 1; i++) {
      json += String(F("\"")) + RegIDs[i] + F("\",");
    }
    json += String(F("\"")) + RegIDs[i] + F("\"");
    json += F("]}");

    String addr = String(F("http://")) + fcm_host + String(F("/fcm/send"));
    HTTPClient http;
    http.begin(addr);
    http.addHeader("Accept", "*/");
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "key=" + fcm_server_key);
    int httpCode = http.POST(json);
    if (httpCode == HTTP_CODE_OK) {
      String result = http.getString();
      DEBUG_PRINT("[HTTP] response: %s\n", result.c_str());
    } else {
      DEBUG_PRINT("[HTTP] POST... failed, error: %d, %s\n", httpCode,
                  http.errorToString(httpCode).c_str());
    }
    http.end();
  }
}
