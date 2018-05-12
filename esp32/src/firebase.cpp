#include <Arduino.h>
#include <HTTPClient.h>

#include <string>

#include "firebase.h"
#include "debug.h"

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

std::string FirebaseRest::RestApi(RestMethod_t method, const std::string path,
                                  const std::string value) {
  HTTPClient http;

  // DEBUG_PRINT("RestApi %s\n", path.c_str());
  std::string post = String(F(".json?auth=")).c_str() + auth_;
  std::string addr = String(F("https://")).c_str() + host_ +
                     String(F("/")).c_str() + path + post;

  http.setTimeout(3000);
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

void FirebaseRest::pushJSON(const String &path, const String &value) {
  String res = RestApi(METHOD_PUSH, path.c_str(), value.c_str()).c_str();
}

void FirebaseRest::pushInt(const String &path, int value) {
  String buf = String(value);
  String res = RestApi(METHOD_PUSH, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::pushFloat(const String &path, float value) {
  String buf = String(value);
  String res = RestApi(METHOD_PUSH, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::pushBool(const String &path, bool value) {
  String buf = String(value);
  String res = RestApi(METHOD_PUSH, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::pushString(const String &path, const String &value) {
  String buf = String(F("\"")) + value + String(F("\""));
  String res = RestApi(METHOD_PUSH, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::setJSON(const String &path, const String &value) {
  String res = RestApi(METHOD_SET, path.c_str(), value.c_str()).c_str();
}

void FirebaseRest::setInt(const String &path, int value) {
  String buf = String(value);
  String res = RestApi(METHOD_SET, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::setFloat(const String &path, float value) {
  String buf = String(value);
  String res = RestApi(METHOD_SET, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::setBool(const String &path, bool value) {
  String buf = String(value);
  String res = RestApi(METHOD_SET, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::setString(const String &path, const String &value) {
  String buf = String(F("\"")) + value + String(F("\""));
  String res = RestApi(METHOD_SET, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::updateJSON(const String &path, const String &value) {
  String res = RestApi(METHOD_UPDATE, path.c_str(), value.c_str()).c_str();
}

void FirebaseRest::updateInt(const String &path, int value) {
  String buf = String(value);
  String res = RestApi(METHOD_UPDATE, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::updateFloat(const String &path, float value) {
  String buf = String(value);
  String res = RestApi(METHOD_UPDATE, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::updateBool(const String &path, bool value) {
  String buf = String(value);
  String res = RestApi(METHOD_UPDATE, path.c_str(), buf.c_str()).c_str();
}

void FirebaseRest::updateString(const String &path, const String &value) {
  String buf = String(F("\"")) + value + String(F("\""));
  String res = RestApi(METHOD_UPDATE, path.c_str(), buf.c_str()).c_str();
}

String FirebaseRest::getJSON(const String &path) {
  String res = RestApi(METHOD_GET, path.c_str(), "").c_str();
  return res;
}

int FirebaseRest::getInt(const String &path) {
  String res = RestApi(METHOD_GET, path.c_str(), "").c_str();
  return res.toInt();
}

float FirebaseRest::getFloat(const String &path) {
  String res = RestApi(METHOD_GET, path.c_str(), "").c_str();
  return res.toFloat();
}

String FirebaseRest::getString(const String &path) {
  std::string res = RestApi(METHOD_GET, path.c_str(), "");
  String ret;
  if (res.size() > 2) {
    ret = res.substr(1, res.size() - 2).c_str();
  } else {
    ret = res.c_str();
  }
  return ret;
}

bool FirebaseRest::getBool(const String &path) {
  String res = RestApi(METHOD_GET, path.c_str(), "").c_str();
  return res.toInt();
}

void FirebaseRest::remove(const String &path) {
  String res = RestApi(METHOD_REMOVE, path.c_str(), "").c_str();
}

bool FirebaseRest::failed() { return httpCode_ != HTTP_CODE_OK; }

String FirebaseRest::error() { return HTTPClient::errorToString(httpCode_); }

FirebaseRest Firebase;
