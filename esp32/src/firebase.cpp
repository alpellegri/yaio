#include <Arduino.h>
#include <HTTPClient.h>

#include <string>

#include "debug.h"
#include "firebase.h"

static const char FcmServer[] PROGMEM = "fcm.googleapis.com";

// Use web browser to view and copy
// SHA1 fingerprint of the certificate
static const char _fingerprint[] PROGMEM =
    "B8:4F:40:70:0C:63:90:E0:07:E8:7D:BD:B4:11:D0:4A:EA:9C:90:F6";

static const char *RestMethods[5] = {
    "GET", "PUT", "POST", "PATCH", "DELETE",
};

void FirebaseRest::begin(const String &host, const String &auth) {
  host_ = host.c_str();
  auth_ = auth.c_str();
}

#ifdef USE_HTTP_REUSE
std::string FirebaseRest::restReqApi(RestMethod_t method,
                                     const std::string path,
                                     const std::string value) {

  // DEBUG_PRINT("restReqApi %s\n", path.c_str());
  std::string post = String(F(".json?auth=")).c_str() + auth_;
  std::string addr = String(F("https://")).c_str() + host_ +
                     String(F("/")).c_str() + path + post;

  http_req.setReuse(true);
  http_req.begin(addr.c_str());
  httpCode_ = http_req.sendRequest(RestMethods[method],
                                   (uint8_t *)value.c_str(), value.length());
  result_ = String(F("")).c_str();
  if (httpCode_ == HTTP_CODE_OK) {
    result_ = http_req.getString().c_str();
    // DEBUG_PRINT("[HTTP] %s\n", result_.c_str());
  } else {
    DEBUG_PRINT("[HTTP] %s... failed, error: %d, %s\n", RestMethods[method],
                httpCode_, http_req.errorToString(httpCode_).c_str());
    http_req.end();
  }

  return result_;
}
#else
std::string FirebaseRest::restReqApi(RestMethod_t method,
                                     const std::string path,
                                     const std::string value) {
  HTTPClient http;

  // DEBUG_PRINT("restReqApi %s\n", path.c_str());
  std::string post = String(F(".json?auth=")).c_str() + auth_;
  std::string addr = String(F("https://")).c_str() + host_ +
                     String(F("/")).c_str() + path + post;

  // http.setReuse(true);
  http.begin(addr.c_str());
  httpCode_ = http.sendRequest(RestMethods[method], (uint8_t *)value.c_str(),
                               value.length());
  result_ = String(F("")).c_str();
  if (httpCode_ == HTTP_CODE_OK) {
    result_ = http.getString().c_str();
    // DEBUG_PRINT("[HTTP] %s\n", result_.c_str());
  } else {
    DEBUG_PRINT("[HTTP] %s... failed, error: %d, %s\n", RestMethods[method],
                httpCode_, http.errorToString(httpCode_).c_str());
  }
  http.end();
  return result_;
}
#endif

void FirebaseRest::pushJSON(const String &path, const String &value) {
  String res = restReqApi(METHOD_PUSH, path.c_str(), value.c_str()).c_str();
}

void FirebaseRest::pushInt(const String &path, int value) {
  String buf = String(value);
  String res = restReqApi(METHOD_PUSH, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::pushFloat(const String &path, float value) {
  String buf = String(value);
  String res = restReqApi(METHOD_PUSH, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::pushBool(const String &path, bool value) {
  String buf = String(value);
  String res = restReqApi(METHOD_PUSH, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::pushString(const String &path, const String &value) {
  String buf = String(F("\"")) + value + String(F("\""));
  String res = restReqApi(METHOD_PUSH, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::setJSON(const String &path, const String &value) {
  String res = restReqApi(METHOD_SET, path.c_str(), value.c_str()).c_str();
}

void FirebaseRest::setInt(const String &path, int value) {
  String buf = String(value);
  String res = restReqApi(METHOD_SET, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::setFloat(const String &path, float value) {
  String buf = String(value);
  String res = restReqApi(METHOD_SET, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::setBool(const String &path, bool value) {
  String buf = (value == true) ? (String(F("true"))) : (String(F("false")));
  String res = restReqApi(METHOD_SET, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::setString(const String &path, const String &value) {
  String buf = String(F("\"")) + value + String(F("\""));
  String res = restReqApi(METHOD_SET, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::updateJSON(const String &path, const String &value) {
  String res = restReqApi(METHOD_UPDATE, path.c_str(), value.c_str()).c_str();
}

void FirebaseRest::updateInt(const String &path, int value) {
  String buf = String(value);
  String res = restReqApi(METHOD_UPDATE, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::updateFloat(const String &path, float value) {
  String buf = String(value);
  String res = restReqApi(METHOD_UPDATE, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::updateBool(const String &path, bool value) {
  String buf = (value == true) ? (String(F("true"))) : (String(F("false")));
  String res = restReqApi(METHOD_UPDATE, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::updateString(const String &path, const String &value) {
  String buf = String(F("\"")) + value + String(F("\""));
  String res = restReqApi(METHOD_UPDATE, path.c_str(), buf.c_str()).c_str();
}

String FirebaseRest::getJSON(const String &path) {
  String res =
      restReqApi(METHOD_GET, path.c_str(), String(F("")).c_str()).c_str();
  return res;
}

int FirebaseRest::getInt(const String &path) {
  String res =
      restReqApi(METHOD_GET, path.c_str(), String(F("")).c_str()).c_str();
  return res.toInt();
}

float FirebaseRest::getFloat(const String &path) {
  String res =
      restReqApi(METHOD_GET, path.c_str(), String(F("")).c_str()).c_str();
  return res.toFloat();
}

String FirebaseRest::getString(const String &path) {
  std::string res = restReqApi(METHOD_GET, path.c_str(), String(F("")).c_str());
  String ret;
  if (res.size() > 2) {
    ret = res.substr(1, res.size() - 2).c_str();
  } else {
    ret = res.c_str();
  }
  return ret;
}

bool FirebaseRest::getBool(const String &path) {
  String res =
      restReqApi(METHOD_GET, path.c_str(), String(F("")).c_str()).c_str();
  return res.equals(String(F("true")));
}

void FirebaseRest::remove(const String &path) {
  String res =
      restReqApi(METHOD_REMOVE, path.c_str(), String(F("")).c_str()).c_str();
}

void FirebaseRest::restStreamApi(const std::string path) {

  DEBUG_PRINT("restStreamApi %s\n", path.c_str());
  std::string post = String(F(".json?auth=")).c_str() + auth_;
  std::string addr = String(F("https://")).c_str() + host_ +
                     String(F("/")).c_str() + path + post;

  http_stream.setReuse(false);
  http_stream.end();
  http_stream.setReuse(true);
  http_stream.begin(addr.c_str());

  http_stream.addHeader(String(F("Accept")), String(F("text/event-stream")));
  const char *headers[] = {"Location"};
  http_stream.collectHeaders(headers, 1);

  httpCode_ = http_stream.sendRequest(RestMethods[METHOD_GET], F(""));

  while (httpCode_ == HTTP_CODE_TEMPORARY_REDIRECT) {
    String location = http_stream.header("Location");
    DEBUG_PRINT("redirect %s\n", location.c_str());
    http_stream.setReuse(false);
    http_stream.end();
    http_stream.setReuse(true);
    http_stream.begin(location);
    httpCode_ = http_stream.sendRequest(RestMethods[METHOD_GET], F(""));
  }

  result_ = String(F("")).c_str();
  if (httpCode_ == HTTP_CODE_OK) {
    // DEBUG_PRINT("[HTTP] %d\n", httpCode_);
  } else {
    DEBUG_PRINT("[HTTP] %s... failed, error: %d, %s\n", RestMethods[METHOD_GET],
                httpCode_, http_stream.errorToString(httpCode_).c_str());
    http_stream.end();
  }
}

void FirebaseRest::stream(const String &path) { restStreamApi(path.c_str()); }

#if 0
int FirebaseRest::readEvent(String &response) {
  int ret = 0;
  response = "";
  WiFiClient *client = http_stream.getStreamPtr();
  if (client == nullptr) {
    DEBUG_PRINT("client == nullptr\n");
    ret = -1;
  } else {
    while (http_stream.connected() && client->available()) {
      String line = client->readString();
      // DEBUG_PRINT("[HTTP] %s\n", line.c_str());
      response += line;
      delay(1);
    }
    ret = response.length();
  }
  // String string = client->readString();
  return ret;
}
#else
int FirebaseRest::readEvent(String &response) {
  int ret = 0;
  response = "";
  WiFiClient *client = http_stream.getStreamPtr();
  if (client == nullptr) {
    DEBUG_PRINT("client == nullptr\n");
    ret = -1;
  } else {
    uint8_t buff[128] = {0};
    while (http_stream.connected() && client->available()) {
      client->read(buff, client->available());
      String line = String((const char *)buff);
      response += line;
      delay(1);
    }
    ret = response.length();
  }
  return ret;
}
#endif

bool FirebaseRest::failed() { return httpCode_ != HTTP_CODE_OK; }

String FirebaseRest::error() { return HTTPClient::errorToString(httpCode_); }

void FirebaseRest::sendMessage(String &message, String &key,
                               std::vector<String> &RegIDs) {
  int i;
  String fcm_host = String(FPSTR(FcmServer));

  //  DATA='{
  //  "notification": {
  //    "body": "this is a body",
  //    "title": "this is a title"
  //  },
  //  "priority": "high",
  //  "data": {
  //    "click_action": "FLUTTER_NOTIFICATION_CLICK",
  //    "id": "1",
  //    "status": "done"
  //  },
  //  "to": "<FCM TOKEN>"}'
  //
  //  curl https://fcm.googleapis.com/fcm/send -H
  //  "Content-Type:application/json" -X POST -d "$DATA" -H "Authorization:
  //  key=<FCM SERVER KEY>"

  /* json data: the notification message multiple devices */
  String json;
  json = F("{");
  json += F("\"notification\":{");
  json += F("\"title\":\"Yaio\",");
  json += F("\"body\":\"");
  json += message;
  json += F("\",");
  json += F("\"sound\":\"default\"");
  json += F("},");

  json += F("\"data\":{");
  json += F("\"click_action\":\"FLUTTER_NOTIFICATION_CLICK\",");
  json += F("\"id\":\"1\",");
  json += F("\"status\":\"done\",");
  json += F("},");

  json += F("\"registration_ids\":[");
  for (i = 0; i < ((int)RegIDs.size() - 1); i++) {
    json += String(F("\"")) + RegIDs[i] + F("\",");
  }
  json += String(F("\"")) + RegIDs[i] + F("\"");
  json += F("]}");

  String addr = String(F("http://")) + fcm_host + String(F("/fcm/send"));
  HTTPClient http;
  http.begin(addr);
  http.addHeader("Accept", "*/");
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "key=" + key);
  int httpCode = http.POST(json);
  if (httpCode == HTTP_CODE_OK) {
    String result = http.getString();
    DEBUG_PRINT("[HTTP] response: %s\n", result.c_str());
  } else {
    DEBUG_PRINT("[HTTP] POST... failed, error: %d, %s\n", httpCode,
                http.errorToString(httpCode).c_str());
  }
  http.end();
}

FirebaseRest Firebase;
