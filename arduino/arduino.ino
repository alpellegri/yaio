#include <ESP8266WiFi.h>
#include <ESP8266WiFiAP.h>
#include <ESP8266WiFiGeneric.h>
#include <ESP8266WiFiMulti.h>
#include <ESP8266WiFiScan.h>
#include <ESP8266WiFiSTA.h>
#include <ESP8266WiFiType.h>
#include <WiFiClient.h>
#include <WiFiClientSecure.h>
#include <WiFiServer.h>
#include <WiFiUdp.h>

#include <EEPROM.h>

#include "fcm.h"

#include <WebSockets.h>
#include <WebSocketsClient.h>
#include <WebSocketsServer.h>

#include <FirebaseArduino.h>

#include <ArduinoJson.h>

#include <Ticker.h>

#include <stdio.h>
#include <string.h>

#define LED     D0 // Led in NodeMCU at pin GPIO16 (D0).
#define BUTTON  D3 // flash button at pin GPIO00 (D3)

#define JSON_BUFFER_SIZE (10*4)

// AP mode: local access
const char* ap_ssid     = "esp8266";
const char* ap_password = "123456789";

// STA mode: router access
char sta_ssid[25] = "";
char sta_password[25] = "";
char firebase_url[50] = "";
char firebase_secret[50] = "";

void setup_ap_mode(void);
void setup_sta_mode(void);
void task(void);

// create sebsocket server
WebSocketsServer webSocket = WebSocketsServer(81);

Ticker flipper;

int mode = 1;
int flip_mode = 1;
int count = 0;
uint8_t *eeprom_ptr;

bool boot = 0;
int cnt = 0;
int button = 0x55;
bool status_alarm = false;
int status_scheduler = 10;
int scheduler_cnt = 0;
bool scheduler_flag = false;
int task_cnt = 0;
int heap_size = 0;
int status_heap = 0;
bool trig_push = false;

void setflip_mode(int mode)
{
  flip_mode = mode;
}

void flip(void)
{
  int trig;

  if (flip_mode == 0)
  {
    trig = (flip_mode == 0)?(1):(5);
    if (count >= trig)
    {
      int state = digitalRead(LED);
      digitalWrite(LED, !state); // set pin to the opposite state
      count = 0;
    }
  }
  else if (flip_mode == 2)
  {
    digitalWrite(LED, 0);
  }
  else
  {
  }
  count++;

  if (scheduler_cnt < status_scheduler)
  {
    scheduler_cnt++;
  }
  else
  {
    scheduler_cnt = 0;
    scheduler_flag = 1;
  }
}

uint8_t LoadWiFiData(uint8_t *data)
{
  uint8_t ret = 0;

  StaticJsonBuffer<200> jsonBuffer;
  JsonObject& root = jsonBuffer.parseObject((char*)data);

  // Test if parsing succeeds.
  if (root.success())
  {
    const char* ssid = root["ssid"];
    const char* password = root["password"];
    const char* firebase = root["firebase"];
    const char* secret = root["secret"];
    if ((ssid != NULL) &&
        (password != NULL) &&
        (firebase != NULL) &&
        (secret != NULL))
    {
      strcpy(sta_ssid, ssid);
      strcpy(sta_password, password);
      strcpy(firebase_url, firebase);
      strcpy(firebase_secret, secret);
      Serial.printf("sta_ssid %s\n", sta_ssid);
      Serial.printf("sta_password %s\n", sta_password);
      Serial.printf("firebase_url %s\n", firebase_url);
      Serial.printf("firebase_secret %s\n", firebase_secret);
      ret = 1;
    }
  }
  else
  {
    Serial.println("parseObject() failed");
  }

  return ret;
}

uint8_t port_id;
void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t lenght)
{
  uint16_t len;
  uint8_t sts;

  switch(type) {
    case WStype_DISCONNECTED:
      Serial.printf("[%u] Disconnected!\n", num);
      setup_sta_mode();
      break;

    case WStype_CONNECTED: {
      setflip_mode(2);
      IPAddress ip = webSocket.remoteIP(num);
      Serial.printf("[%u] Connected from %d.%d.%d.%d url: %s\n", num, ip[0], ip[1], ip[2], ip[3], payload);
      port_id = num;
      }
      break;

    case WStype_TEXT:
      Serial.printf("[%u] get Text: %s\n", num, payload);

      len = strlen((char*)payload);
      if (len != 0)
      {
        // save to epprom
        memcpy(eeprom_ptr, payload, len);
        EEPROM.commit();
      }
      break;

    case WStype_ERROR:
      Serial.printf("[%u] Error!\n", num);
      break;

    default:
      break;
    }
}

void setup_ap_mode()
{
  // static ip for AP mode
  IPAddress ip(192,168,2,1);
  digitalWrite(LED, 1);

  mode = 0;

  WiFi.disconnect();
  WiFi.softAPdisconnect(true);

  port_id = 0xFF;
  setflip_mode(0);
  Serial.printf("connecting mode %d\n", mode);

  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  WiFi.mode(WIFI_AP_STA);

  WiFi.softAPConfig(ip, ip, IPAddress(255,255,255,0));
  WiFi.softAP(ap_ssid, ap_password);

  IPAddress myIP = WiFi.softAPIP();
  Serial.println("AP mode enabled");
  Serial.print("IP address: ");
  Serial.println(myIP);
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
}

void setup_sta_mode()
{
  uint8_t *ee_ptr = eeprom_ptr;
  uint8_t sts;
  int cnt;
  mode = 1;

  WiFi.disconnect();
  WiFi.softAPdisconnect(true);

  setflip_mode(1);
  Serial.printf("connecting mode %d\n", mode);

  Serial.printf("Configuration parameters:\n%s\n", ee_ptr);
  sts = LoadWiFiData(ee_ptr);
  if (sts == 1)
  {
    digitalWrite(LED, 1);
    WiFi.mode(WIFI_STA);
    WiFi.disconnect();
    delay(100);
    WiFi.mode(WIFI_AP_STA);

    Serial.printf("sta_ssid: %s\n", sta_ssid);
    Serial.printf("sta_password: %s\n", sta_password);
    Serial.printf("trying to connect\n", sta_password);
    WiFi.begin(sta_ssid, sta_password);
    cnt = 0;
    while ((WiFi.status() != WL_CONNECTED) && (cnt++<30))
    {
      Serial.print(".");
      delay(500);
    }

    if (WiFi.status() == WL_CONNECTED)
    {
      Serial.println();
      Serial.print("connected: ");
      Serial.println(WiFi.localIP());
      Firebase.begin(firebase_url);
    }
    else
    {
      sts = 0;  
    }
  }

  if (sts != 1)
  {
    Serial.println();
    Serial.println("not connected to router");
    setup_ap_mode();
  }
}

void setup()
{
  mode = 1;

  pinMode(LED, OUTPUT);
  pinMode(BUTTON, INPUT);
  Serial.begin(115200);

  EEPROM.begin(512);
  eeprom_ptr = EEPROM.getDataPtr();

  flipper.attach(0.1, flip);

  Serial.println();
  Serial.println("Starting");
  if (mode == 0) {
    setup_ap_mode();
  } else if (mode == 1) {
    setup_sta_mode();
  }
}

void loop() {
  int in;
  String str;
  char c_str[25] = "";

  // Serial.printf("loop %x\n", cnt);
  // Serial.printf("heap: %d\n\n", ESP.getFreeHeap());

  cnt++;
  if (mode == 0)
  {
    in = digitalRead(BUTTON);
    if (in != button)
    {
      button = in;

      if (button == true)
      {
        if (port_id != 0xFF)
        {
          Serial.printf(">");
          sprintf(c_str, "{\"sensor\":\"%06X\"}", cnt&0xFFFFFF);
          // "{\"sensor\":\"gps\",\"time\":1351824120,\"data\":[48.756080,2.302038]}";
          webSocket.sendTXT(port_id, c_str);
        }
      }
      Serial.printf("cnt: %08X, button %d\n", cnt, button);
    }

    webSocket.loop();
  }
  else if (mode == 1)
  {
    if (scheduler_flag == true)
    {
      scheduler_flag = false;
      task();
    }
  }
}

void task(void)
{
  int in;

  task_cnt++;
  Serial.printf("task_cnt: %d\n", task_cnt);

  if (WiFi.status() == WL_CONNECTED)
  {
    // boot counter
    if (boot == 0)
    {
      Firebase.setBool("control/reboot", false);
      if (Firebase.failed())
      {
        Serial.print("set failed: control/reboot");
        Serial.println(Firebase.error());
      }
      else
      {
        int bootcnt = Firebase.getInt("status/bootcnt");
        if (Firebase.failed())
        {
          Serial.print("get failed: status/bootcnt");
          Serial.println(Firebase.error());
        }
        else
        {
          Serial.printf("status/bootcnt: %d\n", bootcnt);
          Firebase.setInt("status/bootcnt", bootcnt+1);
          if (Firebase.failed())
          {
            Serial.print("set failed: status/bootcnt");
            Serial.println(Firebase.error());
          }
          else
          {
            boot = 1;
            trig_push = true;
          }
        }
      }
    }

    if (boot == true)
    {
      bool control_monitor = Firebase.getBool("control/monitor");
      if ((Firebase.failed() == false) && (control_monitor == true))
      {
        // get object data
        bool control_alarm = Firebase.getBool("control/alarm");
        if (Firebase.failed())
        {
          Serial.print("get failed: control/alarm");
          Serial.println(Firebase.error());  
        }
        else
        {
          if (status_alarm != control_alarm)
          {
            status_alarm = control_alarm;
            digitalWrite(LED, !(status_alarm == true));
            Firebase.setBool("status/alarm", status_alarm);
            if (Firebase.failed())
            {
              Serial.print("set failed: status/alarm");
              Serial.println(Firebase.error());
            }
          }
        }
        // get object data
        bool control_reboot = Firebase.getBool("control/reboot");
        if (Firebase.failed())
        {
          Serial.print("get failed: control/reboot");
          Serial.println(Firebase.error());  
        }
        else
        {
          if (control_reboot == true)
          {
            ESP.restart();
          }
        }
  
        // get object data
        bool control_heap = Firebase.getBool("control/heap");
        if (Firebase.failed())
        {
          Serial.print("get failed: control/heap");
          Serial.println(Firebase.error());  
        }
        else
        {
          if (control_heap == true)
          {
            status_heap = ESP.getFreeHeap();
            Firebase.setInt("status/heap", status_heap);
            if (Firebase.failed())
            {
              Serial.print("set failed: status/heap");
              Serial.println(Firebase.error());
            }
          }
        }
  
        in = digitalRead(BUTTON);
        if (in != button)
        {
          button = in;
          Firebase.setBool("status/button", button);
          if (Firebase.failed())
          {
            Serial.print("set failed: status/button");
            Serial.println(Firebase.error());
          }
          if ((status_alarm == true) && (in == false))
          {
            trig_push = true;
          }
        }

        Firebase.setInt("status/upcnt", task_cnt);
        if (Firebase.failed())
        {
          Serial.print("set failed: status/upcnt");
          Serial.println(Firebase.error());
        }
      }
    }

    if (trig_push == true)
    {
      trig_push = false;
      FcmSendPush();
    }
    FcmService();
  }
}

