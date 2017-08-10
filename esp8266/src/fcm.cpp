#include <Arduino.h>
#include <ESP8266HTTPClient.h>
#include <FirebaseArduino.h>
#include <string.h>

#include "ee.h"
#include "fcm.h"

typedef enum {
  Fcm_Sm_IDLE = 6,
  Fcm_Sm_CONNECT = 0,
  Fcm_Sm_SEND = 1,
  Fcm_Sm_RECEIVE = 2,
  Fcm_Sm_CLOSE = 4,
  Fcm_Sm_ERROR = 5,
} Fbm_StateMachine_t;

const char FcmServer[50] = "fcm.googleapis.com";

WiFiClient fcm_client;
uint16_t fcm_sts = Fcm_Sm_IDLE;
uint16_t FcmServiceTimeout = 0;

// up-to 5 devices
String RegIDs[5];
uint16_t RegIDsLen;
String FcmMessage;

void FcmSendPush(String &message) {
  RegIDsLen = 0;
  FirebaseObject fbRegistration_IDs = Firebase.get("FCM_Registration_IDs");
  if (Firebase.failed() == true) {
    Serial.print(F("get failed: FCM_Registration_IDs"));
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

  if ((RegIDsLen > 0) && (fcm_sts == Fcm_Sm_IDLE)) {
    FcmMessage = message;
    fcm_sts = Fcm_Sm_CONNECT;
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
  FcmServiceTimeout++;

  // Serial.printf("fcm_sts: %d\n", fcm_sts);
  switch (fcm_sts) {

  case Fcm_Sm_CONNECT: {
    FcmServiceTimeout = 0;

    uint32_t retVal = fcm_client.connect(FcmServer, 80);
    if (retVal == -1) {
      Serial.println(F("fcm connect Time out"));
      fcm_sts = Fcm_Sm_IDLE;
    } else if (retVal == -3) {
      Serial.println(F("fcm connect Fail connection"));
      fcm_sts = Fcm_Sm_ERROR;
    } else if (retVal == 1) {
      Serial.println(F("fcm connect Connected with server!"));
      fcm_sts = Fcm_Sm_SEND;
    }
    Serial.printf("retVal: %d\n", retVal);
  } break;

  case Fcm_Sm_SEND: {
    // print and write can be used to send data to a connected
    // client connection.
    String httpPost = FcmPostMsg();
    Serial.println(httpPost);
    fcm_client.print(httpPost);
    fcm_sts = Fcm_Sm_RECEIVE;
  } break;

  case Fcm_Sm_RECEIVE: {
    Serial.println(F("fcm http wait..."));
    // available() will return the number of characters
    // currently in the receive buffer.
    while (fcm_client.available()) {
      yield();
      FcmServiceTimeout = 0;
      Serial.write(fcm_client.read()); // read() gets the FIFO char
    }

    /* close at timeout */
    if (FcmServiceTimeout >= 2) {
      fcm_sts = Fcm_Sm_CLOSE;
    }
  } break;

  case Fcm_Sm_CLOSE: {
    // connected() is a boolean return value - 1 if the
    // connection is active, 0 if it's closed.
    if (fcm_client.connected()) {
      fcm_client.stop(); // stop() closes a TCP connection.
      fcm_sts = Fcm_Sm_IDLE;
    }
  } break;

  case Fcm_Sm_ERROR:
    Serial.println(F("fcm error: end"));
  default:
    fcm_sts = Fcm_Sm_IDLE;
  case Fcm_Sm_IDLE:
    break;
  }
}
