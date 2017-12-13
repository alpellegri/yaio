#include <Arduino.h>

#include "ee.h"

#include <ArduinoJson.h>
#include <EEPROM.h>

#include <stdio.h>
#include <string.h>

#define EE_SIZE 512

// #define PSTR(x) (x)
// #define printf_P printf

static char ee_ssid[30] = "";
static char ee_password[30] = "";
static char ee_uid[30] = "";
static char ee_domain[30] = "";
static char ee_nodename[30] = "";

// do not include 'https://'
static char ee_fb_url[] = "uhome-9b8a1.firebaseio.com";
static char ee_fb_secret[] = "HFfNAKvCGiLhSGwhy1aNTnj1QK6k5lZJukAaKprz";
static char ee_fb_cloud_messaging_server_key[] =
    "AAAAfnPi7d8:APA91bED_durAs8Hn4oyKvaDWQihT_vgRYGKk_Y_"
    "oUkwEpqnctgXUTsnLsiHm241L3RRY9UxcXiHNF3QxBavFmrasx5RjJOk13oETI82c8Awji2ydV"
    "jjruTiZ9Um6Ue72JErI0kwy-Nu";
static char ee_fb_storage_bucket[] = "uhome-9b8a1.firebaseio.com";

void EE_Setup() { EEPROM.begin(EE_SIZE); }

char *EE_GetSSID() { return ee_ssid; }
char *EE_GetPassword() { return ee_password; }
char *EE_GetUID() { return ee_uid; }
char *EE_GetDomain() { return ee_domain; }
char *EE_GetNodeName() { return ee_nodename; }
char *EE_GetFirebaseUrl() { return ee_fb_url; }
char *EE_GetFirebaseSecret() { return ee_fb_secret; }
char *EE_GetFirebaseServerKey() { return ee_fb_cloud_messaging_server_key; }
char *EE_GetFirebaseStorageBucket() { return ee_fb_storage_bucket; }

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
      strcpy(ee_ssid, ssid);
      strcpy(ee_password, password);
      strcpy(ee_uid, uid);
      strcpy(ee_domain, domain);
      strcpy(ee_nodename, nodename);
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
