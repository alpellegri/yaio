#ifndef STA_H
#define STA_H

#include <Arduino.h>

extern bool STA_Setup(void);
extern void STA_Loop(void);
extern bool STA_Task(uint32_t current_time);
extern void STA_FotaReq(void);

#endif
