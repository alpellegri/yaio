#ifndef TIMESRV_H
#define TIMESRV_H

#include <Arduino.h>

extern bool TimeService(void);
extern void TimeSetup(void);
extern uint32_t getTime(void);

#endif
