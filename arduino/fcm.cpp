#include <Arduino.h>
#include <FirebaseArduino.h>
#include <ESP8266HTTPClient.h>

static const String AUTH = "AIza**********************************";
static const String fcm_host = "fcm.googleapis.com";
static char destServer[50] = "fcm.googleapis.com";

WiFiClient client;
int http_sts = 5;

String RegIDs[5];
int RegIDsLen;

void FcmSendPush(void)
{
    boolean res;
    char str[400];

    RegIDsLen = 0;
    res = Firebase.getRaw("FCM_Registration_IDs", str);
    if (res == true)
    {
      StaticJsonBuffer<400> jB;
      JsonObject& root = jB.parseObject(str);
      if (!root.success())
      {
        Serial.println("parseObject() failed");
      }
      else
      {
        for (JsonObject::iterator it=root.begin(); it!=root.end(); ++it)
        {
          Serial.println(it->key);
          Serial.println(it->value.asString());
          RegIDs[RegIDsLen++] = it->value.asString();
        }
      }
    }

  if (RegIDsLen>0)
  {
    http_sts = 0;
  }
}

static String FcmPostMsg(void)
{
  int i;

  // json data: the notification message multiple devices
  String json = "";
  json += "{";
  json +=    "\"data\":{";
  json +=      "\"title\":\"ESP8266 Notification\",";
  json +=      "\"body\":\"Alert!\",";
  json +=      "\"sound\":\"default\"";
  json +=    "},";
  // json +=    "\"registration_ids\":[\"" + REG_ID_0 + "\",\"" + REG_ID_1 + "\"]";
  json +=    "\"registration_ids\":[";
  for (i=0; i<RegIDsLen-1; i++)
  {
    json += "\"" + RegIDs[i] + "\",";
  }
  json += "\"" + RegIDs[i] + "\"";
  json +=    "]";
  json += "}";

  // http post message
  String http = "";
  http += "POST /fcm/send HTTP/1.1\r\n";
  http += "Host: " + fcm_host + "\r\n";
  http += "Accept: */";
  http += "*\r\n";
  http += "Content-Type:application/json" "\r\n";
  http += "Authorization:key=" + AUTH + "\r\n";
  http += "Content-Length: ";
  http += String(json.length());
  http += "\r\n\r\n";
  http += json;
  http += "\r\n\r\n";

  return http;
}

void FcmService(void)
{
  int in;

    // Serial.printf("http_sts: %d\n", http_sts);
    if (http_sts == 0)
    {
      int retVal = client.connect(destServer, 80);
      if (retVal == -1) {
        Serial.println("Time out");
        http_sts = 4;
      } else if (retVal == -3) {
        Serial.println("Fail connection");
        http_sts = 4;
      } else if (retVal == 1) {
        Serial.println("Connected with server!");
        http_sts = 1;
      }
      Serial.printf("retVal: %d\n", retVal);
    }
    else if (http_sts == 1)
    {
      // print and write can be used to send data to a connected
      // client connection.

      String httpPost = FcmPostMsg();
      Serial.println(httpPost);
      client.print(httpPost);
      http_sts = 2;
    }
    else if (http_sts == 2)
    {
      Serial.println("http wait...");
      // available() will return the number of characters
      // currently in the receive buffer.
      while (client.available())
        Serial.write(client.read()); // read() gets the FIFO char

      // connected() is a boolean return value - 1 if the 
      // connection is active, 0 if it's closed.
      if (client.connected())
      {
        client.stop(); // stop() closes a TCP connection.
        http_sts = 5;
      }
    }
    else if (http_sts == 3)
    {
      Serial.println("http successful: end");
    }
    else if (http_sts == 4)
    {
      Serial.println("http error: end");
    }
    else
    {
      Serial.println("http: idle");
    }
}

