
// use weak http connection. i.e. do not close in case of SHA1 finger fails!!!
#include <ESP8266HTTPWeakClient.h>

#include <ESP8266WiFi.h>
#include <MD5Builder.h>
#include <Updater.h>
#include <WiFiUdp.h>
#include <stdlib.h>

#include "ee.h"
#include "vers.h"
#include "fota.h"

static String storage_host = "firebasestorage.googleapis.com";
static const int httpsPort = 443;

static const char *storage_fingerprint =
    "C2:95:F5:7C:8F:23:0A:10:30:86:66:80:7E:83:80:48:E5:B0:06:FF";

static const String file_name = "firmware.bin";
static const String md5file_name = "firmware.md5";

// #define PSTR(x) (x)
// #define printf_P printf

typedef enum {
  FOTA_Sm_IDLE = 0,
  FOTA_Sm_GET_MD5,
  FOTA_Sm_CHECK,
  FOTA_Sm_GET_BLOCK,
  FOTA_Sm_COMPLETE,
  FOTA_Sm_ERROR,
} FOTA_StateMachine_t;

static HTTPWeakClient http;

static const uint16_t block_size = 1024;
static uint16_t block;
static uint16_t num_blocks;

static uint8_t *buffer;

static FOTA_StateMachine_t state = FOTA_Sm_IDLE;
static FOTA_StateMachine_t state_last = FOTA_Sm_IDLE;

static String addr;
static char digest_MD5[32];
static uint8_t http_fail_cnt;

void FOTA_Init(void) {
  //
}

bool FOTA_UpdateReq(void) {
  Serial.println(F("FOTA_UpdateReq"));
  bool ret = false;
  if (state == FOTA_Sm_IDLE) {
    state = FOTA_Sm_GET_MD5;
    http_fail_cnt = 0;
    ret = true;
  }
  return ret;
}

bool FOTAService(void) {

  FOTA_StateMachine_t state_current;
  String storage_bucket = EE_GetFirebaseStorageBucket();

  state_current = state;

  switch (state) {
  case FOTA_Sm_IDLE:
    break;

  case FOTA_Sm_GET_MD5: {
    String md5file_url =
        "/v0/b/" + storage_bucket + "/o/" + VERS_HW_VER + md5file_name + "?alt=media";
    addr = "https://" + storage_host + md5file_url;
    Serial.print(F("FOTA_Sm_GET_MD5 "));
    Serial.println(addr);
    http.setReuse(true);

    bool res = http.begin(addr, storage_fingerprint);
    if (res == true) {
      int httpCode = http.GET();
      // httpCode will be negative on error
      if (httpCode > 0) {
        // HTTP header has been send and Server response header has been handled
        Serial.printf_P(PSTR("[HTTP] GET... code: %d\n"), httpCode);
        // file found at server
        if (httpCode == HTTP_CODE_OK) {
          int size = http.getSize();
          if (size == 32) {
            Serial.printf_P(PSTR("md5file size %d\n"), size);
            String payload = http.getString();
            Serial.println(payload);
            memcpy(digest_MD5, payload.c_str(), 32);
            state = FOTA_Sm_CHECK;
          } else {
            Serial.printf_P(PSTR("md5file size error: %d\n"), size);
            state = FOTA_Sm_ERROR;
          }
        } else {
          Serial.printf_P(PSTR("md5file httpCode error: %d\n"), httpCode);
          state = FOTA_Sm_ERROR;
        }
      } else {
        Serial.printf_P(PSTR("[HTTP] GET... failed, error: %s\n"),
                        http.errorToString(httpCode).c_str());
        state = FOTA_Sm_ERROR;
      }
    } else {
      Serial.printf_P(PSTR("[HTTP] begin... failed, error: %s\n"), res);
      state = FOTA_Sm_ERROR;
    }
  } break;

  case FOTA_Sm_CHECK: {
    String file_url =
        "/v0/b/" + storage_bucket + "/o/" + VERS_HW_VER + file_name + "?alt=media";
    addr = "https://" + storage_host + file_url;
    Serial.print(F("FOTA_Sm_CHECK "));
    Serial.println(addr);
    bool res = http.begin(addr, storage_fingerprint);
    if (res == true) {
      int httpCode = http.GET();
      // httpCode will be negative on error
      if (httpCode > 0) {
        http.end();
        // HTTP header has been send and Server response header has been handled
        Serial.printf_P(PSTR("[HTTP] GET... code: %d\n"), httpCode);
        int size = http.getSize();
        Serial.printf_P(PSTR("file size %d\n"), size);

        block = 0;
        num_blocks = (size + block_size - 1) / block_size;
        if (Update.begin(size, 0)) {
          Update.setMD5(digest_MD5);
          buffer = (uint8_t *)malloc(block_size);
          state = FOTA_Sm_GET_BLOCK;
        } else {
          state = FOTA_Sm_ERROR;
        }
      } else {
        Serial.printf_P(PSTR("file httpCode error: %d\n"), httpCode);
        state = FOTA_Sm_ERROR;
      }
    } else {
      state = FOTA_Sm_ERROR;
    }
  } break;

  case FOTA_Sm_GET_BLOCK: {
    bool res = http.begin(addr, storage_fingerprint);
    if (res == true) {
      String range = "bytes=" + String(block * block_size) + "-" +
                     String(((block + 1) * block_size) - 1);
      http.addHeader("Range", range);
      int httpCode = http.GET();
      // httpCode will be negative on error
      if (httpCode > 0) {
        // HTTP header has been send and Server response header has been handled
        // Serial.printf("[HTTP] GET... code: %d\n", httpCode);

        int len = http.getSize();

        // get tcp stream
        WiFiClient *stream = http.getStreamPtr();
        uint32_t pos = 0;
        bool run = true;
        bool fail = false;

        while (run == true) {
          delay(1);
          if (pos < len) {
            size_t size = stream->available();
            if (size) {
              uint16_t c = stream->readBytes(&buffer[pos], size);
              pos += c;
            }
            if (!http.connected() && (pos < len)) {
              run = false;
              fail = true;
            }
          } else {
            run = false;
          }
        }

        if (fail == false) {
          Update.write(buffer, pos);

          Serial.printf_P(PSTR("[%03d]: %02d%% -- %d\r"), block,
                          100 * block / num_blocks, ESP.getFreeHeap());

          block++;
          if (block < num_blocks) {
            /* move to next block */
            state = FOTA_Sm_GET_BLOCK;
          } else {
            if (!Update.end()) {
              Serial.println(F("Update Error"));
            }
            state = FOTA_Sm_COMPLETE;
          }
        } else {
          state = FOTA_Sm_ERROR;
        }
      } else {
        Serial.printf_P(PSTR("[HTTP] GET... failed, error: %s\n"),
                        http.errorToString(httpCode).c_str());
        state = FOTA_Sm_ERROR;
      }
    } else {
      Serial.printf_P(PSTR("begin error @ %d\n"), block);
      state = FOTA_Sm_ERROR;
    }
  } break;

  case FOTA_Sm_ERROR: {
    if (http_fail_cnt++ < 20) {
      Serial.print(F("retry "));
      Serial.println(http_fail_cnt);
      state = state_last;
    } else {
      /* give-up */
      Serial.println(F("retry give-up"));
      Serial.flush();
      ESP.restart();
    }
  } break;

  case FOTA_Sm_COMPLETE: {
    Serial.println(F("closing connection"));
    Serial.flush();
    free(buffer);
    /* restar node anycase */
    ESP.restart();
    state = FOTA_Sm_IDLE;
  } break;
  }

  state_last = state_current;

  return (state != FOTA_Sm_IDLE);
}
