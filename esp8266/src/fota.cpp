#include <Arduino.h>
#if 0
#include <ESP8266HTTPClient.h>
#else
// use weak http connection. i.e. do not close in case of SHA1 finger fails!!!
#include <ESP8266HTTPWeakClient.h>
#define HTTPClient HTTPWeakClient
#endif

#include <ESP8266WiFi.h>
#include <MD5Builder.h>
#include <Updater.h>
#include <WiFiUdp.h>
#include <stdlib.h>

#include "debug.h"
#include "ee.h"
#include "fota.h"
#include "vers.h"

static const char storage_host[] PROGMEM = "firebasestorage.googleapis.com";
static const int httpsPort = 443;

static const char storage_fingerprint[] PROGMEM =
    "C2:95:F5:7C:8F:23:0A:10:30:86:66:80:7E:83:80:48:E5:B0:06:FF";

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

static HTTPClient *http;

static const uint32_t block_size = 6 * 1500;
static uint32_t block;
static uint32_t num_blocks;

static uint8_t *buffer;

static FOTA_StateMachine_t state = FOTA_Sm_IDLE;
static FOTA_StateMachine_t state_last = FOTA_Sm_IDLE;

static String addr;
#define DIGEST_MD5_SIZE 32
static char *digest_MD5 = NULL;
static uint8_t http_fail_cnt;

bool FOTA_UpdateReq(void) {
  DEBUG_PRINT("FOTA_UpdateReq");
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
    DEBUG_PRINT("FOTA_Sm_GET_MD5 %s\n", addr.c_str());
    http = new HTTPClient;
    http->setReuse(true);
    http->setTimeout(3000);
    bool res = http->begin(addr, storage_fingerprint);
    if (res == true) {
      int httpCode = http->GET();
      // httpCode will be negative on error
      if (httpCode > 0) {
        // HTTP header has been send and Server response header has been handled
        DEBUG_PRINT("[HTTP] GET... code: %d\n", httpCode);
        // file found at server
        if (httpCode == HTTP_CODE_OK) {
          int size = http->getSize();
          if (size == DIGEST_MD5_SIZE) {
            DEBUG_PRINT("md5file size %d\n", size);
            String payload = http->getString();
            DEBUG_PRINT("%s\n", payload.c_str());
            digest_MD5 = (char *)malloc(DIGEST_MD5_SIZE);
            memcpy(digest_MD5, payload.c_str(), DIGEST_MD5_SIZE);
            state = FOTA_Sm_CHECK;
          } else {
            DEBUG_PRINT("md5file size error: %d\n", size);
            state = FOTA_Sm_ERROR;
          }
        } else {
          DEBUG_PRINT("md5file httpCode error: %d\n", httpCode);
          state = FOTA_Sm_ERROR;
        }
      } else {
        DEBUG_PRINT("[HTTP] GET... failed, error: %s\n",
                    http->errorToString(httpCode).c_str());
        state = FOTA_Sm_ERROR;
      }
    } else {
      DEBUG_PRINT("[HTTP] begin... failed, error: %d\n", res);
      state = FOTA_Sm_ERROR;
    }
  } break;

  case FOTA_Sm_CHECK: {
    String file_url = String(F("/v0/b/")) + storage_bucket + String(F("/o/")) +
                      VERS_HW_VER + String(FPSTR(file_name)) +
                      String(F("?alt=media"));
    addr = String(F("https://")) + String(FPSTR(storage_host)) + file_url;
    DEBUG_PRINT("FOTA_Sm_CHECK %s\n", addr.c_str());
    bool res = http->begin(addr, storage_fingerprint);
    if (res == true) {
      int httpCode = http->GET();
      // httpCode will be negative on error
      if (httpCode > 0) {
        http->end();
        // HTTP header has been send and Server response header has been handled
        DEBUG_PRINT("[HTTP] GET... code: %d\n", httpCode);
        int size = http->getSize();
        DEBUG_PRINT("file size %d\n", size);

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
        DEBUG_PRINT("file httpCode error: %d\n", httpCode);
        state = FOTA_Sm_ERROR;
      }
    } else {
      state = FOTA_Sm_ERROR;
    }
  } break;

  case FOTA_Sm_GET_BLOCK: {
    bool res = http->begin(addr, storage_fingerprint);
    if (res == true) {
      String range = String(F("bytes=")) + String(block * block_size) +
                     String(F("-")) + String(((block + 1) * block_size) - 1);
      http->addHeader(String(F("Range")), range);
      int httpCode = http->GET();
      // httpCode will be negative on error
      if (httpCode > 0) {
        // HTTP header has been send and Server response header has been handled
        // Serial.printf("[HTTP] GET... code: %d\n", httpCode);

        int len = http->getSize();

        // get tcp stream
        WiFiClient *stream = http->getStreamPtr();
        int pos = 0;
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
            if (!http->connected() && (pos < len)) {
              run = false;
              fail = true;
            }
          } else {
            run = false;
          }
        }

        if (fail == false) {
          Update.write(buffer, pos);

          DEBUG_PRINT("[%03d]: %02d%% -- %d\r", block, 100 * block / num_blocks,
                      ESP.getFreeHeap());

          block++;
          if (block < num_blocks) {
            /* move to next block */
            state = FOTA_Sm_GET_BLOCK;
          } else {
            if (!Update.end()) {
              DEBUG_PRINT("Update Error\n");
            }
            state = FOTA_Sm_COMPLETE;
          }
        } else {
          state = FOTA_Sm_ERROR;
        }
      } else {
        DEBUG_PRINT("[HTTP] GET... failed, error: %s\n",
                    http->errorToString(httpCode).c_str());
        state = FOTA_Sm_ERROR;
      }
    } else {
      DEBUG_PRINT("begin error @ %d\n", block);
      state = FOTA_Sm_ERROR;
    }
  } break;

  case FOTA_Sm_ERROR: {
    if (http_fail_cnt++ < 20) {
      DEBUG_PRINT("retry %d\n", http_fail_cnt);
      state = state_last;
    } else {
      /* give-up */
      DEBUG_PRINT("retry give-up\n");
      Serial.flush();
      ESP.restart();
    }
  } break;

  case FOTA_Sm_COMPLETE: {
    DEBUG_PRINT("closing connection\n");
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
