#ifndef FCM_H
#define FCM_H

#include <Arduino.h>

extern void FcmService(void);
extern void FcmSendPush(String& message);

#endif
