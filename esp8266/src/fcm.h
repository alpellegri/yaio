#ifndef FCM_H
#define FCM_H

#include <Arduino.h>

extern String FCM_AUTH;
extern char FcmServer[50];
extern char TimeServer[50];

extern void FcmService(void);
extern void FcmSendPush(void);

extern void TimeService(void);

#endif
