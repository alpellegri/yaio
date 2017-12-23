#include <Arduino.h>
#include <HTTPClient.h>
#include <FirebaseArduino.h>
#include <string.h>

#include "ee.h"
#include "fcm.h"

#define FCM_SERVICE_TIMEOUT (5 * 1000)
#define FCM_NUM_REGIDS_MAX (5)

typedef enum {
  Fcm_Sm_IDLE = 0,
  Fcm_Sm_CONNECT,
  Fcm_Sm_SEND,
  Fcm_Sm_RECEIVE,
  Fcm_Sm_CLOSE,
} Fbm_StateMachine_t;

static const char FcmServer[25] = "fcm.googleapis.com";

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
  String fcm_host = String(FcmServer);
  String fcm_server_key = String(EE_GetFirebaseServerKey());

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
  String json = "";
  json += "{";
  json += "\"notification\":{";
  json += "\"title\":\"ESP8266 Alert\",";
  json += "\"body\":\"";
  json += FcmMessage;
  json += "\",";
  json += "\"sound\":\"default\"";
  json += "},";

  json += "\"data\":{";
  json += "\"click_action\":\"FLUTTER_NOTIFICATION_CLICK\",";
  json += "\"id\":\"1\",";
  json += "\"status\":\"done\",";
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
  uint32_t curr_time = millis();

  switch (fcm_sts) {
  case Fcm_Sm_CONNECT: {
    uint32_t retVal = fcm_client.connect(FcmServer, 80);
    if (retVal == 1) {
      Serial.println(F("fcm connect Connected with server!"));
      fcm_sts = Fcm_Sm_SEND;
    } else {
      Serial.println(F("fcm connect error"));
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
    Serial.println(F("fcm http wait..."));
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
