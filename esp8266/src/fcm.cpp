#include <Arduino.h>
#include <ESP8266HTTPClient.h>
#include <FirebaseArduino.h>
#include <string.h>

#include "ee.h"
#include "fcm.h"

const char FcmServer[50] = "fcm.googleapis.com";

WiFiClient fcm_client;
WiFiClient time_client;
uint16_t fcm_sts = 5;

// up-to 5 devices
String RegIDs[5];
uint16_t RegIDsLen;
String FcmMessage;

void FcmSendPush(String &message) {
  RegIDsLen = 0;

  FirebaseObject fbRegistration_IDs = Firebase.get("FCM_Registration_IDs");
  if (Firebase.failed() == true) {
    Serial.print("get failed: FCM_Registration_IDs");
    Serial.println(Firebase.error());
  } else {
    JsonVariant variant = fbRegistration_IDs.getJsonVariant();
    JsonObject &object = variant.as<JsonObject>();
    for (JsonObject::iterator it = object.begin(); it != object.end(); ++it) {
      yield();
      Serial.println(it->key);
      Serial.println(it->value.asString());
      RegIDs[RegIDsLen++] = it->value.asString();
    }
  }

  if ((RegIDsLen > 0) && (fcm_sts == 5)) {
    FcmMessage = message;
    fcm_sts = 0;
  }
}

static String FcmPostMsg(void) {
  int i;
  String fcm_host = String(FcmServer);
  String fcm_server_key = String(EE_GetFirebaseServerKey());

  // json data: the notification message multiple devices
  String json = "";
  json += "{";
  json += "\"data\":{";
  json += "\"title\":\"";
  json += "ESP8266 Alert";
  json += "\",";
  json += "\"body\":\"";
  json += FcmMessage;
  json += "\",";
  json += "\"sound\":\"default\"";
  json += "},";
  json += "\"registration_ids\":[";
  for (i = 0; i < RegIDsLen - 1; i++) {
    json += "\"" + RegIDs[i] + "\",";
  }
  json += "\"" + RegIDs[i] + "\"";
  json += "]";
  json += "}";

  // http post message
  String http = "";
  http += "POST /fcm/send HTTP/1.1\r\n";
  http += "Host: " + fcm_host + "\r\n";
  http += "Accept: */";
  http += "*\r\n";
  http += "Content-Type:application/json\r\n";
  http += "Authorization:key=" + fcm_server_key + "\r\n";
  http += "Content-Length: ";
  http += String(json.length());
  http += "\r\n\r\n";
  http += json;
  http += "\r\n\r\n";

  return http;
}

void FcmService(void) {
  int in;

  // Serial.printf("fcm_sts: %d\n", fcm_sts);
  switch (fcm_sts) {
  case 0: {
    int retVal = fcm_client.connect(FcmServer, 80);
    if (retVal == -1) {
      Serial.println("fcm connect Time out");
      fcm_sts = 4;
    } else if (retVal == -3) {
      Serial.println("fcm connect Fail connection");
      fcm_sts = 4;
    } else if (retVal == 1) {
      Serial.println("fcm connect Connected with server!");
      fcm_sts = 1;
    }
    Serial.printf("retVal: %d\n", retVal);
  } break;

  case 1: {
    // print and write can be used to send data to a connected
    // client connection.
    String httpPost = FcmPostMsg();
    Serial.println(httpPost);
    fcm_client.print(httpPost);
    fcm_sts = 2;
  } break;

  case 2: {
    Serial.println("fcm http wait...");
    // available() will return the number of characters
    // currently in the receive buffer.
    while (fcm_client.available()) {
      yield();
      Serial.write(fcm_client.read()); // read() gets the FIFO char
    }

    // connected() is a boolean return value - 1 if the
    // connection is active, 0 if it's closed.
    if (fcm_client.connected()) {
      fcm_client.stop(); // stop() closes a TCP connection.
      fcm_sts = 5;
    }
  } break;

  case 4: {
    Serial.println("fcm error: end");
  } break;

  case 5:
  default: {
    fcm_sts = 5;
    // Serial.println("fcm: idle");
    break;
  }
  }
}
