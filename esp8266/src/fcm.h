#ifndef FCM_H
#define FCM_H

#include <Arduino.h>

extern void FcmDeinitRegIDsDB(void);
extern void FcmAddRegIDsDB(String string);
extern void FcmSendPush(String &message);

#endif
