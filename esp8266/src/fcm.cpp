#include <Arduino.h>
#include <ArduinoJson.h>

#include <string.h>
#include <vector>

#include "debug.h"
#include "ee.h"
#include "fbconf.h"
#include "fbutils.h"
#include "fcm.h"
#include "firebase.h"

void FcmSendPush(String &message) {
  std::vector<TokenEntry> ids = FB_getRegIDs();

  String response;
  if (ids.size() > 0) {
    std::vector<String> tokens;
    for (uint32_t i = 0; i < ids.size(); i++) {
      tokens.push_back(ids[i].value);
    }
    String fcm_server_key = EE_GetFirebaseServerKey();
    response = Firebase.sendMessage(message, fcm_server_key, tokens);

    DEBUG_PRINT("%s\n", response.c_str());
    DynamicJsonDocument doc(4096);
    auto error = deserializeJson(doc, response);
    if (!error) {
      JsonObject object = doc.as<JsonObject>();
      JsonArray results = object[F("results")].as<JsonArray>();
      String fcmtoken_path = FbGetPath_fcmtoken();
      for (uint32_t i = 0; i < results.size(); ++i) {
        if (results[i][F("error")] != nullptr) {
          String data = results[i][F("error")].as<String>();
          DEBUG_PRINT("[FCM][%d] data: %s\n", i, data.c_str());
          // Firebase.remove(data);
          String path = fcmtoken_path + "/" + ids[i].key;
          DEBUG_PRINT("remove token: %s\n", path.c_str());
          FB_clearRegIDsDB(i);
          Firebase.remove(path);
        }
      }
    }
  }
}
