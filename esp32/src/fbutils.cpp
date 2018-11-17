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

void FB_addIoEntryDB(String key, JsonObject &obj) {
  if (IoEntryVec.size() < NUM_IO_ENTRY_MAX) {
    IoEntry entry;
    entry.key = key;
    entry.code = obj[F("code")].as<uint8_t>();
    entry.value = obj[F("value")].as<String>();
    entry.ioctl = obj[F("ioctl")].as<uint32_t>();
    entry.enLog = obj[F("enLog")].as<bool>();
    entry.enWrite = obj[F("drawWr")].as<bool>();
    entry.enRead = obj[F("drawRd")].as<bool>();
    // TODO: can be done a setup here
    entry.ev = false;
    entry.ev_value = 0;
    entry.ev_tmstamp = 0;
    entry.ev_tmstamp_log = 0;
    entry.wb = false;
    entry.cb = obj[F("cb")].as<String>();

    // post process data value for some case
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
      PHT_Set(entry.ioctl);
    } break;
    case kRadioRx: {
      RF_SetRxPin(entry.ioctl);
    } break;
    case kRadioTx: {
      RF_SetTxPin(entry.ioctl);
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

void FB_addProgDB(String key, JsonObject &obj) {
  ProgEntry entry;
  entry.key = key;
  DEBUG_PRINT("FB_addProgDB: key=%s\n", entry.key.c_str());

  JsonArray &nest = obj[F("p")].as<JsonArray>();
  for (uint32_t i = 0; i < nest.size(); ++i) {
    FuncEntry fentry;
    fentry.code = nest[i][F("i")].as<int>();
    if (nest[i][F("v")].as<String>()) {
      fentry.value = nest[i][F("v")].as<String>();
    }
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
        "%d: key=%s, code=%d, value=%s, ioctl=%x, ev=%d, ev_value=%d, cb=%s\n",
        i, IoEntryVec[i].key.c_str(), IoEntryVec[i].code,
        IoEntryVec[i].value.c_str(), IoEntryVec[i].ioctl, IoEntryVec[i].ev,
        IoEntryVec[i].ev_value, IoEntryVec[i].cb.c_str());
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
