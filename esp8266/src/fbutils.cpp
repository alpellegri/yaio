#include <Arduino.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>
#include <string>
#include <vector>

#include "fbutils.h"
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

void FB_addIoEntryDB(String key, String name, uint8_t code, String value,
                     String cb) {
  if (IoEntryVec.size() < NUM_IO_ENTRY_MAX) {
    IoEntry entry;
    entry.key = key;
    entry.name = name;
    entry.code = code;
    entry.value = value;
    if (code == kRadioRx) {
      uint8_t pin = atoi(value.c_str()) >> 24;
      RF_SetRxPin(pin);
    } else if (code == kRadioTx) {
      uint8_t pin = atoi(value.c_str()) >> 24;
      RF_SetTxPin(pin);
    }
    // TODO: can be done a setup here
    entry.cb = cb;
    entry.ev = false;
    entry.ev_value = 0;
    entry.wb = false;
    IoEntryVec.push_back(entry);
  }
}

String &FB_getIoEntryNameById(uint8_t i) {
  IoEntry &entry = IoEntryVec[i];
  return entry.name;
}

void FB_addProgDB(String key, JsonObject &obj) {
  ProgEntry entry;
  entry.key = key;
  entry.name = obj["name"].asString();
  DEBUG_PRINT("FB_addProgDB: key=%s, name=%s\n", entry.key.c_str(),
              entry.name.c_str());

  JsonArray &nest = obj["p"].asArray();
  for (uint32_t i = 0; i < nest.size(); ++i) {
    FuncEntry fentry;
    fentry.code = nest[i]["i"].as<int>();
    if (nest[i]["v"].asString()) {
      fentry.value = nest[i]["v"].asString();
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
  DEBUG_PRINT("FB_dumpIoEntry");
  for (uint8_t i = 0; i < IoEntryVec.size(); ++i) {
    DEBUG_PRINT("%d: key=%s, name=%s, code=%d, value=%s, cb=%s\n", i,
        IoEntryVec[i].key.c_str(), IoEntryVec[i].name.c_str(),
        IoEntryVec[i].code, IoEntryVec[i].value.c_str(),
        IoEntryVec[i].cb.c_str());
  }
}

void FB_dumpProg(void) {
  DEBUG_PRINT("FB_dumpProg");
  for (uint8_t i = 0; i < ProgVec.size(); ++i) {
    DEBUG_PRINT("%d: key=%s, name=%s\n", i, ProgVec[i].key.c_str(),
                    ProgVec[i].name.c_str());
    for (uint8_t j = 0; j < ProgVec[i].funcvec.size(); j++) {
      DEBUG_PRINT("%d: code=%d, value=%s\n", j,
                      ProgVec[i].funcvec[j].code,
                      ProgVec[i].funcvec[j].value.c_str());
    }
  }
}
