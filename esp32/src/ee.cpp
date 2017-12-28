#include <Arduino.h>

#include "ee.h"

#include <ArduinoJson.h>
#include <EEPROM.h>

#include <stdio.h>
#include <string.h>

#define EE_SIZE 512

static String ee_ssid;
static String ee_password;
static String ee_uid;
static String ee_domain;
static String ee_nodename;

// do not include 'https://'
String ee_fb_url = "uhome-9b8a1.firebaseio.com";
String ee_fb_secret = "HFfNAKvCGiLhSGwhy1aNTnj1QK6k5lZJukAaKprz";
String ee_fb_cloud_messaging_server_key =
    "AAAAfnPi7d8:APA91bED_durAs8Hn4oyKvaDWQihT_vgRYGKk_Y_"
    "oUkwEpqnctgXUTsnLsiHm241L3RRY9UxcXiHNF3QxBavFmrasx5RjJOk13oETI82c8Awji2ydV"
    "jjruTiZ9Um6Ue72JErI0kwy-Nu";
String ee_fb_storage_bucket = "uhome-9b8a1.appspot.com";

void EE_Setup() { EEPROM.begin(EE_SIZE); }

String EE_GetSSID() { return ee_ssid; }
String EE_GetPassword() { return ee_password; }
String EE_GetUID() { return ee_uid; }
String EE_GetDomain() { return ee_domain; }
String EE_GetNodeName() { return ee_nodename; }
String EE_GetFirebaseUrl() { return ee_fb_url; }
String EE_GetFirebaseSecret() { return ee_fb_secret; }
String EE_GetFirebaseServerKey() { return ee_fb_cloud_messaging_server_key; }
String EE_GetFirebaseStorageBucket() { return ee_fb_storage_bucket; }

void EE_EraseData() {
  int i;

  for (i = 0; i < EE_SIZE; i++) {
    yield();
    EEPROM.write(i, 0);
  }
  EEPROM.commit();
}

void EE_StoreData(uint8_t *data, uint16_t len) {
  uint16_t i;

  Serial.println(F("EE_StoreData"));
  for (i = 0; i < len; i++) {
    yield();
    EEPROM.write(i, data[i]);
  }
  EEPROM.commit();
}

bool EE_LoadData(void) {
  bool ret = false;
  char data[EE_SIZE];
  uint16_t i;

  Serial.println(F("EEPROM loading..."));
  for (i = 0; i < EE_SIZE; i++) {
    yield();
    data[i] = EEPROM.read(i);
    Serial.printf_P(PSTR("%c"), data[i]);
  }
  Serial.println();

  DynamicJsonBuffer jsonBuffer;
  JsonObject &root = jsonBuffer.parseObject(data);

  // Test if parsing succeeds.
  if (root.success() == 1) {
    const char *ssid = root["ssid"];
    Serial.print(F("ssid: "));
    Serial.println(ssid);
    const char *password = root["password"];
    Serial.print(F("password: "));
    Serial.println(password);
    const char *uid = root["uid"];
    Serial.print(F("uid: "));
    Serial.println(uid);
    const char *domain = root["domain"];
    Serial.print(F("domain: "));
    Serial.println(domain);
    const char *nodename = root["nodename"];
    Serial.print(F("nodename: "));
    Serial.println(nodename);
    if ((ssid != NULL) && (password != NULL) && (uid != NULL) &&
        (domain != NULL) && (nodename != NULL)) {
      ee_ssid = String(ssid);
      ee_password = String(password);
      ee_uid = String(uid);
      ee_domain = String(domain);
      ee_nodename = String(nodename);
      Serial.println(F("EEPROM ok"));
      ret = true;
    } else {
      Serial.println(F("EEPROM content not ok"));
    }
  } else {
    Serial.println(F("parseObject() failed"));
  }

  return ret;
}
