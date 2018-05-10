#include <Arduino.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>
#include <string>
#include <vector>

#include "fbutils.h"
#include "pht.h"
#include "rf.h"

#define DEBUG_PRINT(fmt, ...) Serial.printf_P(PSTR(fmt), ##__VA_ARGS__)

std::vector<IoEntry> IoEntryVec;
std::vector<ProgEntry> ProgVec;

void FB_deinitIoEntryDB(void) {
  IoEntryVec.erase(IoEntryVec.begin(), IoEntryVec.end());
}

void FB_deinitProgDB(void) { ProgVec.erase(ProgVec.begin(), ProgVec.end()); }

IoEntry &FB_getIoEntry(uint8_t i) { return IoEntryVec[i]; }

uint8_t FB_getIoEntryLen(void) { return IoEntryVec.size(); }

ProgEntry &FB_getProg(uint8_t i) { return ProgVec[i]; }

uint8_t FB_getProgLen(void) { return ProgVec.size(); }

void FB_addIoEntryDB(String key, JsonObject &obj) {
  if (IoEntryVec.size() < NUM_IO_ENTRY_MAX) {
    IoEntry entry;
    entry.key = key;
    entry.code = obj["code"].as<uint8_t>();
    entry.value = obj["value"].as<String>();

    // post process data value for some case
    switch (entry.code) {
    case kDhtTemperature:
    case kDhtHumidity: {
      // 31..24 pin
      // 23..16 period
      // 15..0 value
      uint32_t value = atoi(entry.value.c_str());
      uint8_t pin = value >> 24;
      uint32_t mask = ((1 << 8) - 1) << 16;
      uint32_t period = (value & mask) >> 16;
      PHT_Set(pin, period);
    } break;
    case kRadioRx: {
      uint8_t pin = atoi(entry.value.c_str()) >> 24;
      RF_SetRxPin(pin);
    } break;
    case kRadioTx: {
      uint8_t pin = atoi(entry.value.c_str()) >> 24;
      RF_SetTxPin(pin);
    } break;
    case kBool: {
      if (entry.value == F("false")) {
        entry.value = F("0");
      } else if (entry.value == F("true")) {
        entry.value = F("1");
      } else {
        DEBUG_PRINT("kBool error\n");
        entry.value = F("0");
      }
    } break;
    default:
      break;
    }
    entry.cb = obj["cb"].as<String>();
    // TODO: can be done a setup here
    entry.ev = false;
    entry.ev_value = 0;
    entry.wb = false;
    IoEntryVec.push_back(entry);
  }
}

String &FB_getIoEntryNameById(uint8_t i) {
  IoEntry &entry = IoEntryVec[i];
  return entry.key;
}

void FB_addProgDB(String key, JsonObject &obj) {
  ProgEntry entry;
  entry.key = key;
  DEBUG_PRINT("FB_addProgDB: key=%s\n", entry.key.c_str());

  JsonArray &nest = obj["p"].as<JsonArray>();
  for (uint32_t i = 0; i < nest.size(); ++i) {
    FuncEntry fentry;
    fentry.code = nest[i]["i"].as<int>();
    if (nest[i]["v"].as<String>()) {
      fentry.value = nest[i]["v"].as<String>();
    }
    entry.funcvec.push_back(fentry);
  }
  ProgVec.push_back(entry);
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
    DEBUG_PRINT("%d: key=%s, code=%d, value=%s, cb=%s\n", i,
                IoEntryVec[i].key.c_str(), IoEntryVec[i].code,
                IoEntryVec[i].value.c_str(), IoEntryVec[i].cb.c_str());
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
