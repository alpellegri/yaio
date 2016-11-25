#include <Arduino.h>

#include "ee.h"

#include <ArduinoJson.h>
#include <EEPROM.h>

#include <stdio.h>
#include <string.h>

#define EE_SIZE 512

char sta_ssid[25] = "";
char sta_password[25] = "";
char firebase_url[50] = "";
char firebase_secret[50] = "";
char firebase_server_key[50] = "";

void EE_Setup() { EEPROM.begin(EE_SIZE); }

char *EE_GetSSID() { return sta_ssid; }

char *EE_GetPassword() { return sta_password; }

char *EE_GetFirebaseUrl() {
  /* strip 8 chars: "https://" */
  return &firebase_url[8];
}

char *EE_GetFirebaseSecret() { return firebase_secret; }

char *EE_GetFirebaseServerKey() { return firebase_server_key; }

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

  for (i = 0; i < EE_SIZE; i++) {
    yield();
    data[i] = EEPROM.read(i);
  }

  StaticJsonBuffer<400> jsonBuffer;
  JsonObject &root = jsonBuffer.parseObject(data);

  // Test if parsing succeeds.
  if (root.success() == 1) {
    const char *ssid = root["ssid"];
    const char *password = root["password"];
    const char *firebase = root["firebase_url"];
    const char *secret = root["secret"];
    const char *server_key = root["server_key"];
    if ((ssid != NULL) && (password != NULL) && (firebase != NULL) &&
        (secret != NULL) && (server_key != NULL)) {
      strcpy(sta_ssid, ssid);
      strcpy(sta_password, password);
      strcpy(firebase_url, firebase);
      strcpy(firebase_secret, secret);
      strcpy(firebase_server_key, server_key);
      Serial.printf("sta_ssid %s\n", sta_ssid);
      Serial.printf("sta_password %s\n", sta_password);
      Serial.printf("firebase_url %s\n", firebase_url);
      Serial.printf("firebase_secret %s\n", firebase_secret);
      Serial.printf("firebase_server_key %s\n", firebase_server_key);
      ret = true;
    }
  } else {
    Serial.println("parseObject() failed");
  }

  return ret;
}
