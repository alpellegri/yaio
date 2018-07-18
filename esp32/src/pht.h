#ifndef PHT_H
#define PHT_H

#include <Arduino.h>

extern void PHT_Set(uint8_t pin, uint32_t period);
extern bool PHT_GetTemperature(uint16_t *t);
extern bool PHT_GetHumidity(uint16_t *h);
extern void PHT_Service(void);

#endif
