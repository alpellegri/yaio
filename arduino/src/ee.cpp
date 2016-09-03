#include <Arduino.h>

#include "ee.h"

#include <EEPROM.h>
#include <ArduinoJson.h>

#include <stdio.h>
#include <string.h>

#define EE_SIZE 512

char sta_ssid[25] = "";
char sta_password[25] = "";
char firebase_url[50] = "";
char firebase_secret[50] = "";

void EE_setup()
{
	EEPROM.begin(EE_SIZE);
}

char *EE_GetSSID()
{
	return sta_ssid;
}

char *EE_GetPassword()
{
	return sta_password;
}

char *EE_GetFirebaseUrl()
{
	return firebase_url;
}

char *EE_GetFirebaseSecret()
{
	return firebase_secret;
}

void EE_StoreData(uint8_t *data, uint16_t len)
{
	int i;

	for (i=0; i<len; i++)
	{
		yield();
		EEPROM.write(i, data[i]);
	}
	EEPROM.commit();
}

bool EE_LoadData(void)
{
	bool ret = false;
	char data[EE_SIZE];
	int i;

	for (i=0; i<EE_SIZE; i++)
	{
		yield();
		data[i] = EEPROM.read(i);
	}

	StaticJsonBuffer<200> jsonBuffer;
	JsonObject& root = jsonBuffer.parseObject(data);

	// Test if parsing succeeds.
	if (root.success() == 1)
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
			ret = true;
		}
	}
	else
	{
		Serial.println("parseObject() failed");
	}

	return ret;
}
