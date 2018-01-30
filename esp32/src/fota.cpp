
// use weak http connection. i.e. do not close in case of SHA1 finger fails!!!
#include <HTTPClient.h>

#include <WiFi.h>
#include <MD5Builder.h>
#include <Update.h>
#include <WiFiUdp.h>
#include <stdlib.h>

#include "ee.h"
#include "fota.h"
#include "vers.h"

static const char storage_host[] PROGMEM = "firebasestorage.googleapis.com";
static const int httpsPort = 443;

static const char file_name[] PROGMEM = "firmware.bin";
static const char md5file_name[] PROGMEM = "firmware.md5";

typedef enum {
  FOTA_Sm_IDLE = 0,
  FOTA_Sm_GET_MD5,
  FOTA_Sm_CHECK,
  FOTA_Sm_GET_BLOCK,
  FOTA_Sm_COMPLETE,
  FOTA_Sm_ERROR,
} FOTA_StateMachine_t;

static HTTPClient http;

static const uint16_t block_size = 8*1500;
static uint16_t block;
static uint16_t num_blocks;

static uint8_t *buffer;

static FOTA_StateMachine_t state = FOTA_Sm_IDLE;
static FOTA_StateMachine_t state_last = FOTA_Sm_IDLE;

static String addr;
// static char digest_MD5[32];
#define DIGEST_MD5_SIZE 32
static char *digest_MD5 = NULL;
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
    String md5file_url = String(F("/v0/b/")) + storage_bucket +
                         String(F("/o/")) + VERS_HW_VER +
                         String(FPSTR(md5file_name)) + String(F("?alt=media"));
    addr = String(F("https://")) + String(FPSTR(storage_host)) + md5file_url;
    Serial.print(F("FOTA_Sm_GET_MD5 "));
    Serial.println(addr);
    http.setReuse(true);

    bool res = http.begin(addr);
    if (res == true) {
      int httpCode = http.GET();
      // httpCode will be negative on error
      if (httpCode > 0) {
        // HTTP header has been send and Server response header has been handled
        Serial.printf_P(PSTR("[HTTP] GET... code: %d\n"), httpCode);
        // file found at server
        if (httpCode == HTTP_CODE_OK) {
          int size = http.getSize();
          if (size == DIGEST_MD5_SIZE) {
            Serial.printf_P(PSTR("md5file size %d\n"), size);
            String payload = http.getString();
            Serial.println(payload);
            digest_MD5 = (char *)malloc(DIGEST_MD5_SIZE);
            memcpy(digest_MD5, payload.c_str(), DIGEST_MD5_SIZE);
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
    String file_url = String(F("/v0/b/")) + storage_bucket + String(F("/o/")) +
                      VERS_HW_VER + String(FPSTR(file_name)) +
                      String(F("?alt=media"));
    addr = String(F("https://")) + String(FPSTR(storage_host)) + file_url;
    Serial.print(F("FOTA_Sm_CHECK "));
    Serial.println(addr);
    bool res = http.begin(addr);
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
    bool res = http.begin(addr);
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
