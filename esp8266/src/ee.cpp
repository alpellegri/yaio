#include <Arduino.h>

#include "ee.h"

#include <ArduinoJson.h>
#include <EEPROM.h>

#include <stdio.h>
#include <string.h>

#define EE_SIZE 512

char sta_ssid[25] = "";
char sta_password[25] = "";
char sta_firebase_url[50] = "";
char sta_firebase_secret[50] = "";
char sta_firebase_server_key[50] = "";

void EE_Setup() { EEPROM.begin(EE_SIZE); }

char *EE_GetSSID() { return sta_ssid; }

char *EE_GetPassword() { return sta_password; }

char *EE_GetFirebaseUrl() { return sta_firebase_url; }

char *EE_GetFirebaseSecret() { return sta_firebase_secret; }

char *EE_GetFirebaseServerKey() { return sta_firebase_server_key; }

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
    // Serial.printf("%c", data[i]);
    EEPROM.write(i, data[i]);
  }
  // Serial.printf("\n");
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
    Serial.printf("%c", data[i]);
  }
  Serial.printf("\n");

  DynamicJsonBuffer jsonBuffer;
  JsonObject &root = jsonBuffer.parseObject(data);

  // Test if parsing succeeds.
  if (root.success() == 1) {
    const char *ssid = root["ssid"];
    Serial.print(F("ssid "));
    Serial.println(ssid);
    const char *password = root["password"];
    Serial.print(F("password "));
    Serial.println(password);
    const char *firebase_url = root["firebase_url"];
    Serial.print(F("firebase_url "));
    Serial.println(firebase_url);
    const char *firebase_secret = root["firebase_secret"];
    Serial.print(F("firebase_secret "));
    Serial.println(firebase_secret);
    const char *firebase_server_key = root["firebase_server_key"];
    Serial.print(F("firebase_server_key "));
    Serial.println(firebase_server_key);
    if ((ssid != NULL) && (password != NULL) && (firebase_url != NULL) &&
        (firebase_secret != NULL) && (firebase_server_key != NULL)) {
      strcpy(sta_ssid, ssid);
      strcpy(sta_password, password);
      strcpy(sta_firebase_url, firebase_url);
      strcpy(sta_firebase_secret, firebase_secret);
      strcpy(sta_firebase_server_key, firebase_server_key);
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
