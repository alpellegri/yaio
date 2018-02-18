#ifndef PHT_H
#define PHT_H

#include <Arduino.h>

extern void PHT_Set(uint8_t pin, uint32_t period);
extern uint32_t PHT_GetTemperature(void);
extern uint32_t PHT_GetHumidity(void);
extern void PHT_Service(void);

#endif
