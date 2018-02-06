#ifndef FCM_H
#define FCM_H

#include <Arduino.h>

extern void FcmResetRegIDsDB(void);
extern void FcmAddRegIDsDB(String string);
extern void FcmSendPush(String &message);

#endif
