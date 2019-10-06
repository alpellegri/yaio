#ifndef firebase_h
#define firebase_h

#include <Arduino.h>
#include <ESP8266HTTPClient.h>
#include <ESP8266WiFi.h>
#include <WiFiClient.h>

// #define USE_HTTP_REUSE
// #define USE_HTTP_STREAM

typedef enum {
  METHOD_GET = 0,
  METHOD_SET,
  METHOD_PUSH,
  METHOD_UPDATE,
  METHOD_REMOVE,
} RestMethod_t;

class FirebaseRest {
public:
  void begin(const String &host, const String &auth = "");
  void pushInt(const String &path, int value);
  void pushFloat(const String &path, float value);
  void pushBool(const String &path, bool value);
  void pushString(const String &path, const String &value);
  void pushJSON(const String &path, const String &value);
  void setInt(const String &path, int value);
  void setFloat(const String &path, float value);
  void setBool(const String &path, bool value);
  void setString(const String &path, const String &value);
  void setJSON(const String &path, const String &value);
  void updateInt(const String &path, int value);
  void updateFloat(const String &path, float value);
  void updateBool(const String &path, bool value);
  void updateString(const String &path, const String &value);
  void updateJSON(const String &path, const String &value);
  int getInt(const String &path);
  float getFloat(const String &path);
  String getString(const String &path);
  bool getBool(const String &path);
  String getJSON(const String &path);
  void remove(const String &path);
  void stream(const String &path);
  int readEvent(String &response);
  bool failed();
  String error();
  String sendMessage(String &message, String &key,
                     std::vector<String> &tokens);

private:
  String &restReqApi(RestMethod_t method, const String path,
                     const String value);
  void restStreamApi(const String path);

  String _host;
  String _auth;
  String _result;
  int _httpCode;
#ifdef USE_HTTP_REUSE
  HTTPClient _http_req;
  BearSSL::WiFiClientSecure _client_req;
#endif
#ifdef USE_HTTP_STREAM
  HTTPClient _http_stream;
  BearSSL::WiFiClientSecure _client_stream;
#endif
};

extern FirebaseRest Firebase;

#endif // firebase_h
