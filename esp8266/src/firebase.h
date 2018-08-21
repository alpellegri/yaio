#ifndef firebase_h
#define firebase_h

#include <Arduino.h>
#if 0
#include <ESP8266HTTPClient.h>
#else
// use weak http connection. i.e. do not close in case of SHA1 finger fails!!!
#include <ESP8266HTTPWeakClient.h>
#define HTTPClient HTTPWeakClient
#endif

#include <string>
#include <vector>

typedef enum {
  METHOD_GET,
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
  bool available();
  bool connected();
  String readEvent();
  bool failed();
  String error();
  void sendMessage(String &message, String &key, std::vector<String> &RegIDs);

private:
  std::string restReqApi(RestMethod_t method, const std::string path,
                         const std::string value);
  std::string _restReqApi(RestMethod_t method, const std::string path,
                          const std::string value);
  void restStreamApi(const std::string path);

  std::string host_;
  std::string auth_;
  std::string result_;
  int httpCode_;
  HTTPClient http_req;
  HTTPClient http_stream;
};

extern FirebaseRest Firebase;

#endif // firebase_h
