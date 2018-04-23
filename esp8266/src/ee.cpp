#include <Arduino.h>

#include "ee.h"

#include <ArduinoJson.h>
#include <EEPROM.h>

#include <stdio.h>
#include <string.h>

#define DEBUG_PRINT(fmt, ...) Serial.printf_P(PSTR(fmt), ##__VA_ARGS__)

#define EE_SIZE 512

static String ee_ssid;
static String ee_password;
static String ee_uid;
static String ee_domain;
static String ee_nodename;

// do not include 'https://'
static const char ee_fb_url[] PROGMEM = "uhome-9b8a1.firebaseio.com";
static const char ee_fb_secret[] PROGMEM =
    "HFfNAKvCGiLhSGwhy1aNTnj1QK6k5lZJukAaKprz";
static const char ee_fb_cloud_messaging_server_key[] PROGMEM =
    "AAAAfnPi7d8:APA91bED_durAs8Hn4oyKvaDWQihT_vgRYGKk_Y_"
    "oUkwEpqnctgXUTsnLsiHm241L3RRY9UxcXiHNF3QxBavFmrasx5RjJOk13oETI82c8Awji2ydV"
    "jjruTiZ9Um6Ue72JErI0kwy-Nu";
static const char ee_fb_storage_bucket[] PROGMEM = "uhome-9b8a1.appspot.com";

void EE_Setup() { EEPROM.begin(EE_SIZE); }

String EE_GetSSID() { return ee_ssid; }
String EE_GetPassword() { return ee_password; }
String EE_GetUID() { return ee_uid; }
String EE_GetDomain() { return ee_domain; }
String EE_GetNodeName() { return ee_nodename; }
String EE_GetFirebaseUrl() { return FPSTR(ee_fb_url); }
String EE_GetFirebaseSecret() { return FPSTR(ee_fb_secret); }
String EE_GetFirebaseServerKey() {
  return FPSTR(ee_fb_cloud_messaging_server_key);
}
String EE_GetFirebaseStorageBucket() { return FPSTR(ee_fb_storage_bucket); }

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

  DEBUG_PRINT("EE_StoreData\n");
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

  DEBUG_PRINT("EEPROM loading...\n");
  for (i = 0; i < EE_SIZE; i++) {
    yield();
    data[i] = EEPROM.read(i);
    DEBUG_PRINT("%c", data[i]);
  }
  DEBUG_PRINT("\n");

  DynamicJsonBuffer jsonBuffer;
  JsonObject &root = jsonBuffer.parseObject(data);

  // Test if parsing succeeds.
  if (root.success() == 1) {
    const char *ssid = root[FPSTR("ssid")];
    DEBUG_PRINT("ssid: %s\n", ssid);
    const char *password = root[FPSTR("password")];
    DEBUG_PRINT("password: %s\n", password);
    const char *uid = root[FPSTR("uid")];
    DEBUG_PRINT("uid: %s\n", uid);
    const char *domain = root[FPSTR("domain")];
    DEBUG_PRINT("domain: %s\n", domain);
    const char *nodename = root[FPSTR("nodename")];
    DEBUG_PRINT("nodename: %s\n", nodename);
    if ((ssid != NULL) && (password != NULL) && (uid != NULL) &&
        (domain != NULL) && (nodename != NULL)) {
      ee_ssid = String(ssid);
      ee_password = String(password);
      ee_uid = String(uid);
      ee_domain = String(domain);
      ee_nodename = String(nodename);
      DEBUG_PRINT("EEPROM ok\n");
      ret = true;
    } else {
      DEBUG_PRINT("EEPROM content not ok\n");
    }
  } else {
    DEBUG_PRINT("parseObject() failed\n");
  }

  return ret;
}
