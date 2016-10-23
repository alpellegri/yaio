#ifndef EEPROM_H
#define EEPROM_H

#include <Arduino.h>

extern void EE_Setup();
extern char *EE_GetSSID();
extern char *EE_GetPassword();
extern char *EE_GetFirebaseUrl();
extern char *EE_GetFirebaseSecret();
extern char *EE_GetFirebaseServerKey();
extern void EE_EraseData(void);
extern void EE_StoreData(uint8_t *data, uint16_t len);
extern bool EE_LoadData(void);

#endif
