#include <Arduino.h>
#if 0
#include <ESP8266HTTPClient.h>
#else
// use weak http connection. i.e. do not close in case of SHA1 finger fails!!!
#include <ESP8266HTTPWeakClient.h>
#define HTTPClient HTTPWeakClient
#endif

#include <string.h>
#include <vector>

#include "debug.h"
#include "ee.h"
#include "fcm.h"
#include "firebase.h"

#define FCM_NUM_REGIDS_MAX (5)

static std::vector<String> RegIDs;

void FcmDeinitRegIDsDB(void) { RegIDs.erase(RegIDs.begin(), RegIDs.end()); }

void FcmAddRegIDsDB(String string) {
  if (RegIDs.size() < FCM_NUM_REGIDS_MAX) {
    RegIDs.push_back(string);
  }
}

void FcmSendPush(String &message) {
  if (RegIDs.size() > 0) {
    String fcm_server_key = EE_GetFirebaseServerKey();
    Firebase.sendMessage(message, fcm_server_key, RegIDs);
  }
}
