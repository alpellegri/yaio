#include <Arduino.h>
#include <ESP8266HTTPClient.h>
#include <FirebaseArduino.h>
#include <string.h>

#include "ee.h"
#include "fcm.h"

#define DEBUG_PRINT(fmt, ...) Serial.printf_P(PSTR(fmt), ##__VA_ARGS__)

#define FCM_SERVICE_TIMEOUT (5 * 1000)
#define FCM_NUM_REGIDS_MAX (5)

typedef enum {
  Fcm_Sm_IDLE = 0,
  Fcm_Sm_CONNECT,
  Fcm_Sm_SEND,
  Fcm_Sm_RECEIVE,
  Fcm_Sm_CLOSE,
} Fbm_StateMachine_t;

static const char FcmServer[] PROGMEM = "fcm.googleapis.com";

static WiFiClient fcm_client;
static uint16_t fcm_sts = Fcm_Sm_IDLE;
static uint32_t FcmServiceStamp;
static bool FcmServiceRxRun;
static bool FcmServiceRxStop;

// up-to 5 devices
static String RegIDs[FCM_NUM_REGIDS_MAX];
static uint8_t RegIDsLen;
static String FcmMessage;

void FcmResetRegIDsDB(void) { RegIDsLen = 0; }

void FcmAddRegIDsDB(String string) {
  if (RegIDsLen < FCM_NUM_REGIDS_MAX) {
    RegIDs[RegIDsLen] = string;
    RegIDsLen++;
  }
}

void FcmSendPush(String &message) {
  if ((RegIDsLen > 0) && (fcm_sts == Fcm_Sm_IDLE)) {
    FcmMessage = message;
    fcm_sts = Fcm_Sm_CONNECT;
  }
}

static String FcmPostMsg(void) {
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
  json += F("\"title\":\"ESP8266 Alert\",");
  json += F("\"body\":\"");
  json += FcmMessage;
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

  // http post message
  String http;
  http = F("POST /fcm/send HTTP/1.1\r\n");
  http += String(F("Host: ")) + fcm_host + F("\r\n");
  http += F("Accept: */");
  http += F("*\r\n");
  http += F("Content-Type:application/json\r\n");
  http += String(F("Authorization:key=")) + fcm_server_key + F("\r\n");
  http += F("Content-Length: ");
  http += String(json.length());
  http += F("\r\n\r\n");
  http += json;
  http += F("\r\n\r\n");

  return http;
}

void FcmService(void) {
  uint32_t curr_time = millis();

  switch (fcm_sts) {
  case Fcm_Sm_CONNECT: {
    uint32_t retVal = fcm_client.connect(String(FPSTR(FcmServer)).c_str(), 80);
    if (retVal == 1) {
      DEBUG_PRINT("fcm connect Connected with server!\n");
      fcm_sts = Fcm_Sm_SEND;
    } else {
      DEBUG_PRINT("fcm connect error\n");
      fcm_sts = Fcm_Sm_CLOSE;
    }
  } break;

  case Fcm_Sm_SEND: {
    // print and write can be used to send data to a connected
    // client connection.
    String httpPost = FcmPostMsg();
    Serial.println(httpPost);
    fcm_client.print(httpPost);
    FcmServiceStamp = curr_time;
    FcmServiceRxRun = false;
    FcmServiceRxStop = false;
    fcm_sts = Fcm_Sm_RECEIVE;
  } break;

  case Fcm_Sm_RECEIVE: {
    DEBUG_PRINT("fcm http wait...\n");
    /* close at timeout or communication complete */
    if (((curr_time - FcmServiceStamp) > FCM_SERVICE_TIMEOUT) ||
        (FcmServiceRxStop == true)) {
      fcm_sts = Fcm_Sm_CLOSE;
    } else {
      // available() will return the number of characters
      // currently in the receive buffer.
      uint32_t avail = fcm_client.available();

      if (avail > 0) {
        FcmServiceRxRun = true;
        /* retrig timeout on receive */
        FcmServiceStamp = curr_time;
        while (avail--) {
          Serial.write(fcm_client.read()); // read() gets the FIFO char
          // fcm_client.read();
        }
      } else {
        FcmServiceRxStop = FcmServiceRxRun;
      }
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
  }
}
