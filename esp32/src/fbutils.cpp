#include <Arduino.h>

#include <stdio.h>
#include <string.h>
#include <string>
#include <vector>

#include "debug.h"
#include "fbutils.h"
#include "pht.h"
#include "pio.h"
#include "rf.h"

static std::vector<String> RegIDs;
static std::vector<IoEntry> IoEntryVec;
static std::vector<ProgEntry> ProgVec;

void FB_deinitRegIDsDB(void) { RegIDs.erase(RegIDs.begin(), RegIDs.end()); }

void FB_addRegIDsDB(String string) {
  if (RegIDs.size() < NUM_REGIDS_MAX) {
    RegIDs.push_back(string);
  }
}

std::vector<String> &FB_getRegIDs() { return RegIDs; }

void FB_deinitIoEntryDB(void) {
  IoEntryVec.erase(IoEntryVec.begin(), IoEntryVec.end());
}

IoEntry &FB_getIoEntry(uint8_t i) { return IoEntryVec[i]; }

uint8_t FB_getIoEntryLen(void) { return IoEntryVec.size(); }

void FB_addIoEntryDB(String key, cJSON *obj) {
  if (IoEntryVec.size() < NUM_IO_ENTRY_MAX) {
    cJSON *data;
    IoEntry entry;
    entry.key = key;
    DEBUG_PRINT("FB_addIoEntryDB: key=%s\n", entry.key.c_str());
    data = cJSON_GetObjectItemCaseSensitive(obj, FPSTR("code"));
    entry.code = data->valueint;
    // entry.value = data->valuestring;
    data = cJSON_GetObjectItemCaseSensitive(obj, FPSTR("ioctl"));
    entry.ioctl = data->valueint;
    data = cJSON_GetObjectItem(obj, FPSTR("enLog"));
    if (data != NULL) {
      if (cJSON_IsTrue(data) == 1) {
        entry.enLog = true;
      } else if (cJSON_IsFalse(data) == 1) {
        entry.enLog = false;
      } else {
        DEBUG_PRINT("FB_addIoEntryDB: bool error\n");
      }
    } else {
      entry.enLog = false;
    }
    data = cJSON_GetObjectItem(obj, FPSTR("drawWr"));
    if (data != NULL) {
      if (cJSON_IsTrue(data) == 1) {
        entry.enWrite = true;
      } else if (cJSON_IsFalse(data) == 1) {
        entry.enWrite = false;
      } else {
        DEBUG_PRINT("FB_addIoEntryDB: bool error\n");
      }
    } else {
      entry.enWrite = false;
    }
    data = cJSON_GetObjectItem(obj, FPSTR("drawRd"));
    if (data != NULL) {
      if (cJSON_IsTrue(data) == 1) {
        entry.enRead = true;
      } else if (cJSON_IsFalse(data) == 1) {
        entry.enRead = false;
      } else {
        DEBUG_PRINT("FB_addIoEntryDB: bool error\n");
      }
    } else {
      entry.enRead = false;
    }
    data = cJSON_GetObjectItemCaseSensitive(obj, FPSTR("cb"));
    if (data != NULL) {
      entry.cb = data->valuestring;
    } else {
      entry.cb = F("");
    }
    // TODO: can be done a setup here
    entry.ev = false;
    entry.ev_value = F("");
    entry.ev_tmstamp = 0;
    entry.ev_tmstamp_log = 0;
    entry.wb = false;

    // post process data value for some case
    data = cJSON_GetObjectItemCaseSensitive(obj, FPSTR("value"));
    if (cJSON_IsString(data)) {
      entry.value = data->valuestring;
    } else if (cJSON_IsNumber(data)) {
      entry.value = data->valueint;
    } else if (cJSON_IsTrue(data)) {
      entry.value = F("1");
    } else if (cJSON_IsFalse(data)) {
      entry.value = F("0");
    } else {
      DEBUG_PRINT("FB_addIoEntryDB: value error\n");
    }
    switch (entry.code) {
    case kPhyDIn:
    case kPhyAIn: {
      PIO_Set(entry.code, entry.ioctl);
    } break;
    case kPhyDOut: {
      uint32_t value = atoi(entry.value.c_str());
      uint16_t ioctl = entry.ioctl;
      pinMode(ioctl, OUTPUT);
      digitalWrite(ioctl, !!value);
    } break;
    case kDhtTemperature:
    case kDhtHumidity: {
      /* override with float */
      if (cJSON_IsNumber(data)) {
        entry.value = data->valuedouble;
      } else {
        DEBUG_PRINT("FB_addIoEntryDB: value error\n");
      }
      PHT_Set(entry.ioctl);
    } break;
    case kRadioRx: {
      RF_SetRxPin(entry.ioctl);
    } break;
    case kRadioTx: {
      RF_SetTxPin(entry.ioctl);
    } break;
    case kFloat: {
      /* override with float */
      if (cJSON_IsNumber(data)) {
        entry.value = data->valuedouble;
      } else {
        DEBUG_PRINT("FB_addIoEntryDB: value error\n");
      }
    } break;
    default:
      break;
    }
    IoEntryVec.push_back(entry);
  }
}

String &FB_getIoEntryNameById(uint8_t i) {
  IoEntry &entry = IoEntryVec[i];
  return entry.key;
}

uint8_t FB_getIoEntryIdx(const char *key) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;
  uint8_t res;

  while ((i < IoEntryVec.size()) && (idx == 0xFF)) {
    res = strcmp(IoEntryVec[i].key.c_str(), key);
    if (res == 0) {
      idx = i;
    }
    i++;
  }

  return idx;
}

void FB_deinitProgDB(void) { ProgVec.erase(ProgVec.begin(), ProgVec.end()); }

ProgEntry &FB_getProg(uint8_t i) { return ProgVec[i]; }

uint8_t FB_getProgLen(void) { return ProgVec.size(); }

void FB_addProgDB(String key, cJSON *obj) {
  ProgEntry entry;
  entry.key = key;
  DEBUG_PRINT("FB_addProgDB: key=%s\n", entry.key.c_str());
  cJSON *array = cJSON_GetObjectItemCaseSensitive(obj, FPSTR("p"));
  int i;
  for (i = 0; i < cJSON_GetArraySize(array); i++) {
    cJSON *item = cJSON_GetArrayItem(array, i);
    // handle subitem
    FuncEntry fentry;
    fentry.code = cJSON_GetObjectItemCaseSensitive(item, FPSTR("i"))->valueint;
    fentry.value =
        cJSON_GetObjectItemCaseSensitive(item, FPSTR("v"))->valuestring;
    entry.funcvec.push_back(fentry);
  }
  ProgVec.push_back(entry);
}

uint8_t FB_getProgIdx(const char *key) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;
  uint8_t res;

  while ((i < ProgVec.size()) && (idx == 0xFF)) {
    res = strcmp(ProgVec[i].key.c_str(), key);
    if (res == 0) {
      idx = i;
    }
    i++;
  }
  return idx;
}

void FB_dumpIoEntry(void) {
  DEBUG_PRINT("FB_dumpIoEntry\n");
  for (uint8_t i = 0; i < IoEntryVec.size(); ++i) {
    DEBUG_PRINT(
        "%d: key=%s, code=%d, value=%s, ioctl=%x, ev=%d, ev_value=%s, cb=%s\n",
        i, IoEntryVec[i].key.c_str(), IoEntryVec[i].code,
        IoEntryVec[i].value.c_str(), IoEntryVec[i].ioctl, IoEntryVec[i].ev,
        IoEntryVec[i].ev_value.c_str(), IoEntryVec[i].cb.c_str());
  }
}

void FB_dumpProg(void) {
  DEBUG_PRINT("FB_dumpProg\n");
  for (uint8_t i = 0; i < ProgVec.size(); ++i) {
    DEBUG_PRINT("%d: key=%s\n", i, ProgVec[i].key.c_str());
    for (uint8_t j = 0; j < ProgVec[i].funcvec.size(); j++) {
      DEBUG_PRINT("  %d: code=%d, value=%s\n", j, ProgVec[i].funcvec[j].code,
                  ProgVec[i].funcvec[j].value.c_str());
    }
  }
}
