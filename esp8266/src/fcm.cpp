#include <Arduino.h>

#include <string.h>
#include <vector>

#include "ee.h"
#include "fbutils.h"
#include "fcm.h"
#include "firebase.h"

void FcmSendPush(String &message) {
  std::vector<String> ids = FB_getRegIDs();
  if (ids.size() > 0) {
    String fcm_server_key = EE_GetFirebaseServerKey();
    Firebase.sendMessage(message, fcm_server_key, ids);
  }
}
