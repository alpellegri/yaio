#ifndef TIMESRV_H
#define TIMESRV_H

#include <Arduino.h>

typedef struct {
  uint8_t Second;
  uint8_t Minute;
  uint8_t Hour;
  uint8_t Wday; // day of week, sunday is day 1
  uint8_t Day;
  uint8_t Month;
  uint16_t Year;
} tmElements_t;

extern bool TimeService(void);
extern char* getTmUTC(void);
extern tmElements_t getTmTime(void);

#endif
