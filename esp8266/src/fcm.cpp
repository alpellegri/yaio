#include "ee.h"
#include "fcm.h"
#include <Arduino.h>
#include <ESP8266HTTPClient.h>
#include <FirebaseArduino.h>
#include <string.h>

const char FcmServer[50] = "fcm.googleapis.com";
const char TimeServer[50] = "google.com";

WiFiClient fcm_client;
WiFiClient time_client;
uint16_t fcm_sts = 5;
uint16_t time_sts = 0;

// up-to 5 devices
String RegIDs[5];
uint16_t RegIDsLen;
char FcmMessage[50];

void FcmSendPush(char *message) {
  RegIDsLen = 0;

  FirebaseObject fbRegistration_IDs = Firebase.get("FCM_Registration_IDs");
  if (Firebase.failed() == true) {
    Serial.print("get failed: FCM_Registration_IDs");
    Serial.println(Firebase.error());
  } else {
    JsonVariant variant = fbRegistration_IDs.getJsonVariant();
    JsonObject &object = variant.as<JsonObject>();
    for (JsonObject::iterator it = object.begin(); it != object.end(); ++it) {
      Serial.println(it->key);
      Serial.println(it->value.asString());
      RegIDs[RegIDsLen++] = it->value.asString();
    }
  }

  if ((RegIDsLen > 0) && (fcm_sts == 5)) {
    strcpy(FcmMessage, message);
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
  json += String(FcmMessage);
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
    Serial.println("fcm: idle");
    break;
  }
  }
}

void TimeService(void) {
  int in;

  Serial.printf("time_sts: %d\n", time_sts);
  switch (time_sts) {
  case 0: {
    int retVal = time_client.connect(TimeServer, 80);
    if (retVal == -1) {
      Serial.println("time connect Time out");
      time_sts = 4;
    } else if (retVal == -3) {
      Serial.println("time connect Fail connection");
      time_sts = 4;
    } else if (retVal == 1) {
      Serial.println("time connect Connected with server!");
      time_sts = 1;
    }
    Serial.printf("retVal: %d\n", retVal);
  } break;

  case 1: {
    // print and write can be used to send data to a connected
    // client connection.
    time_client.print("HEAD / HTTP/1.1\r\n\r\n");
    time_sts = 2;
  } break;

  case 2: {
    Serial.println("time http wait...");
    // available() will return the number of characters
    // currently in the receive buffer.
    while (time_client.available()) {
      String line = time_client.readStringUntil('\r');
      Serial.println("message google time start");
      Serial.println(line);
      Serial.println("message google time stop");
    }

    // connected() is a boolean return value - 1 if the
    // connection is active, 0 if it's closed.
    if (time_client.connected()) {
      time_client.stop(); // stop() closes a TCP connection.
      time_sts = 0;
    }
  } break;

  case 4: {
    Serial.println("time http error: end");
    time_sts = 0;
  } break;

  case 5:
  default: {
    Serial.println("time http: idle");
    time_sts = 0;
  } break;
  }
}
