#ifndef EEPROM_H
#define EEPROM_H

#include <Arduino.h>

extern void EE_Setup();
extern String EE_GetSSID();
extern String EE_GetPassword();
extern String EE_GetUID();
extern String EE_GetDomain();
extern String EE_GetNode();
extern String EE_GetFirebaseUrl();
extern String EE_GetFirebaseSecret();
extern String EE_GetFirebaseServerKey();
extern String EE_GetFirebaseStorageBucket();
extern void EE_EraseData(void);
extern void EE_StoreData(uint8_t *data, uint16_t len);
extern bool EE_LoadData(void);

#endif
