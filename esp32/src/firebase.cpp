#include <Arduino.h>
#include <HTTPClient.h>
#include <WiFiClient.h>

#include <string>

#include "debug.h"
#include "firebase.h"

static const char FcmServer[] PROGMEM = "fcm.googleapis.com";

#if 1
static const char *RestMethods[] = {
    "GET", "PUT", "POST", "PATCH", "DELETE",
};
#else
static const char _get[] PROGMEM = "GET";
static const char _put[] PROGMEM = "PUT";
static const char _post[] PROGMEM = "POST";
static const char _patch[] PROGMEM = "PATCH";
static const char _delete[] PROGMEM = "DELETE";
static const char *RestMethods[] = {
    _get, _put, _post, _patch, _delete,
};
#endif

void FirebaseRest::begin(const String &host, const String &auth) {
  _host = host;
  _auth = auth;
}

#ifdef USE_HTTP_REUSE
String FirebaseRest::restReqApi(RestMethod_t method, const String path,
                                const String value) {

  String path_ = String(F("/")) + path + String(F(".json"));
  String post = String(F("?auth=")) + _auth;
  if (method != METHOD_GET) {
    post += String(F("&print=silent"));
  }
  String addr = String(F("https://")) + _host + path_ + post;
  // DEBUG_PRINT("[HTTP] addr: %s\n", addr.c_str());

  _http_req.setReuse(true);
  // _http_req.setTimeout(3000);

  _http_req.begin(_client_req, addr);
  _httpCode = _http_req.sendRequest(RestMethods[method], value);

  if ((_httpCode == HTTP_CODE_OK) || (_httpCode == HTTP_CODE_NO_CONTENT)) {
    // DEBUG_PRINT("[HTTP] size: %d %d\n", _httpCode, _http_req.getSize());
    _result = _http_req.getString();
    // DEBUG_PRINT("[HTTP] response: %s\n", _result.c_str());
  } else {
    _result = String(F(""));
    DEBUG_PRINT("[HTTP] %s... failed, error: %d, %s\n", RestMethods[method],
                _httpCode, _http_req.errorToString(_httpCode).c_str());
    _http_req.end();
  }

  return _result;
}
#else
String FirebaseRest::restReqApi(RestMethod_t method, const String path,
                                const String value) {

  HTTPClient http;
  String path_ = String(F("/")) + path + String(F(".json"));
  String post = String(F("?auth=")) + _auth;
  if (method != METHOD_GET) {
    post += String(F("&print=silent"));
  }
  String addr = String(F("https://")) + _host + path_ + post;
  // DEBUG_PRINT("[HTTP] addr: %s\n", addr.c_str());

  // http.setTimeout(3000);
  http.begin(addr);
  _httpCode = http.sendRequest(RestMethods[method], value);

  if ((_httpCode == HTTP_CODE_OK) || (_httpCode == HTTP_CODE_NO_CONTENT)) {
    _result = http.getString();
    // DEBUG_PRINT("[HTTP] _result: %s\n", _result.c_str());
  } else {
    _result = String(F(""));
    DEBUG_PRINT("[HTTP] %s... failed, error: %d, %s\n", RestMethods[method],
                _httpCode, http.errorToString(_httpCode).c_str());
  }
  http.end();

  return _result;
}
#endif

void FirebaseRest::pushJSON(const String &path, const String &value) {
  String res = restReqApi(METHOD_PUSH, path, value);
}

void FirebaseRest::pushInt(const String &path, int value) {
  String buf = String(value);
  String res = restReqApi(METHOD_PUSH, path, buf);
}

void FirebaseRest::pushFloat(const String &path, float value) {
  String buf = String(value);
  String res = restReqApi(METHOD_PUSH, path, buf);
}

void FirebaseRest::pushBool(const String &path, bool value) {
  String buf = String(value);
  String res = restReqApi(METHOD_PUSH, path, buf);
}

void FirebaseRest::pushString(const String &path, const String &value) {
  String buf = String(F("\"")) + value + String(F("\""));
  String res = restReqApi(METHOD_PUSH, path, buf);
}

void FirebaseRest::setJSON(const String &path, const String &value) {
  String res = restReqApi(METHOD_SET, path, value);
}

void FirebaseRest::setInt(const String &path, int value) {
  String buf = String(value);
  String res = restReqApi(METHOD_SET, path, buf);
}

void FirebaseRest::setFloat(const String &path, float value) {
  String buf = String(value);
  String res = restReqApi(METHOD_SET, path, buf);
}

void FirebaseRest::setBool(const String &path, bool value) {
  String buf = (value == true) ? (String(F("true"))) : (String(F("false")));
  String res = restReqApi(METHOD_SET, path, buf);
}

void FirebaseRest::setString(const String &path, const String &value) {
  String buf = String(F("\"")) + value + String(F("\""));
  String res = restReqApi(METHOD_SET, path, buf);
}

void FirebaseRest::updateJSON(const String &path, const String &value) {
  String res = restReqApi(METHOD_UPDATE, path, value);
}

void FirebaseRest::updateInt(const String &path, int value) {
  String buf = String(value);
  String res = restReqApi(METHOD_UPDATE, path, buf);
}

void FirebaseRest::updateFloat(const String &path, float value) {
  String buf = String(value);
  String res = restReqApi(METHOD_UPDATE, path, buf);
}

void FirebaseRest::updateBool(const String &path, bool value) {
  String buf = (value == true) ? (String(F("true"))) : (String(F("false")));
  String res = restReqApi(METHOD_UPDATE, path, buf);
}

void FirebaseRest::updateString(const String &path, const String &value) {
  String buf = String(F("\"")) + value + String(F("\""));
  String res = restReqApi(METHOD_UPDATE, path, buf);
}

String FirebaseRest::getJSON(const String &path) {
  String res = restReqApi(METHOD_GET, path, String());
  return res;
}

int FirebaseRest::getInt(const String &path) {
  String res = restReqApi(METHOD_GET, path, String());
  return res.toInt();
}

float FirebaseRest::getFloat(const String &path) {
  String res = restReqApi(METHOD_GET, path, String());
  return res.toFloat();
}

String FirebaseRest::getString(const String &path) {
  String res = restReqApi(METHOD_GET, path, String());
  String ret;
  if (res.length() > 2) {
    ret = res.substring(1, res.length() - 2);
  } else {
    ret = res;
  }
  return ret;
}

bool FirebaseRest::getBool(const String &path) {
  String res = restReqApi(METHOD_GET, path, String());
  return res.equals(String(F("true")));
}

void FirebaseRest::remove(const String &path) {
  String res = restReqApi(METHOD_REMOVE, path, String());
}

#ifdef USE_HTTP_STREAM
void FirebaseRest::restStreamApi(const String path) {

  // DEBUG_PRINT("restStreamApi %s\n", path.c_str());
  String post = String(F(".json?auth=")) + _auth;
  String addr = String(F("https://")) + _host + String(F("/")) + path + post;

  _http_stream.setReuse(false);
  _http_stream.end();
  _http_stream.setReuse(true);
  // http_stream.setTimeout(3000);
  _http_stream.begin(_client_stream, addr);

  _http_stream.addHeader(String(F("Accept")), String(F("text/event-stream")));
  const char *headers[] = {"Location"};
  _http_stream.collectHeaders(headers, 1);

  _httpCode = _http_stream.GET();

  while (_httpCode == HTTP_CODE_TEMPORARY_REDIRECT) {
    String location = _http_stream.header(String(FPSTR("Location")).c_str());
    DEBUG_PRINT("redirect %s\n", location.c_str());
    _http_stream.setReuse(false);
    _http_stream.end();
    _http_stream.setReuse(true);
    _http_stream.begin(_client_stream, location);
    _httpCode = _http_stream.GET();
  }

  _result = String(F(""));
  if (_httpCode == HTTP_CODE_OK) {
    // DEBUG_PRINT("[HTTP] %d\n", _httpCode);
  } else {
    DEBUG_PRINT("[HTTP] %s... failed, error: %d, %s\n", RestMethods[METHOD_GET],
                _httpCode, _http_stream.errorToString(_httpCode).c_str());
    _http_stream.end();
  }
}

void FirebaseRest::stream(const String &path) { restStreamApi(path); }

int FirebaseRest::readEvent(String &response) {
  int ret = 0;
  response = F("");
  uint8_t buff[64];
  uint8_t bsize = sizeof(buff) - 1;
  size_t size;
  while (_http_stream.connected() && (size = _client_stream.available())) {
    uint16_t rsize = ((size > bsize) ? bsize : size);
    _client_stream.read(buff, rsize);
    buff[rsize] = 0;
    String line((char *)buff);
    // DEBUG_PRINT("client: (%d,%d) %s\n", size, rsize, line.c_str());
    response += line;
    delay(10);
  }
  ret = response.length();
  if (_http_stream.connected() == false) {
    ret = -1;
  }
  return ret;
}
#endif

bool FirebaseRest::failed() {
  return !((_httpCode == HTTP_CODE_OK) || (_httpCode == HTTP_CODE_NO_CONTENT));
}

String FirebaseRest::error() { return HTTPClient::errorToString(_httpCode); }

void FirebaseRest::sendMessage(String &message, String &key,
                               std::vector<String> &RegIDs) {
  uint32_t i;
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
  for (i = 0; i < RegIDs.size(); i++) {
    json += String(F("\"")) + RegIDs[i] + F("\",");
  }
  json += F("]}");

  String addr = String(F("https://")) + fcm_host + String(F("/fcm/send"));
  WiFiClientSecure client;
  HTTPClient http;
  http.begin(client, addr);
  // http.addHeader(String(F("Accept")), String(F("*/")));
  http.addHeader(String(F("Content-Type")), String(F("application/json")));
  http.addHeader(String(F("Authorization")), String(F("key=")) + key);
  // DEBUG_PRINT("json: %s\n", json.c_str());
  int httpCode = http.POST(json);
  if (httpCode == HTTP_CODE_OK) {
#if 0
    String response = http.getString();
#else
    String response;
    uint8_t buff[64];
    uint8_t bsize = sizeof(buff) - 1;
    int size;
    while ((size = client.available()) > 0) {
      uint16_t rsize = ((size > bsize) ? bsize : size);
      client.read(buff, rsize);
      buff[rsize] = 0;
      String line((char *)buff);
      response += line;
    }
#endif
    DEBUG_PRINT("[HTTP] response: %s\n", response.c_str());
    // DEBUG_PRINT("[HTTP] size: %d %d\n", httpCode, client.available());
  } else {
    DEBUG_PRINT("[HTTP] POST... failed, error: %d, %s\n", httpCode,
                http.errorToString(httpCode).c_str());
  }
  http.end();
}

FirebaseRest Firebase;
