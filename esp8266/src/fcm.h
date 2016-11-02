#ifndef FCM_H
#define FCM_H

#include <Arduino.h>

extern void FcmService(void);
extern void FcmSendPush(char *message);

extern void TimeService(void);

#endif
