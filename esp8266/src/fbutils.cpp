#include <Arduino.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>
#include <string>
#include <vector>

#include "fbutils.h"

static std::vector<IoEntry> IoEntryVec;
static std::vector<FunctionEntry> FunctionVec;

void FB_deinitIoEntryDB(void) {
  IoEntryVec.erase(IoEntryVec.begin(), IoEntryVec.end());
}

void FB_deinitFunctionDB(void) {
  FunctionVec.erase(FunctionVec.begin(), FunctionVec.end());
}

IoEntry FB_getIoEntry(uint8_t i) { return IoEntryVec[i]; }

uint8_t FB_getIoEntryLen(void) { return IoEntryVec.size(); }

FunctionEntry FB_getFunction(uint8_t i) { return FunctionVec[i]; }

uint8_t FB_getFunctionLen(void) { return FunctionVec.size(); }

void FB_addIoEntryDB(String key, uint8_t type, String id, String name,
                     String func) {
  if (IoEntryVec.size() < NUM_IO_ENTRY_MAX) {
    IoEntry entry;
    entry.key = key;
    entry.type = type;
    entry.id = atoi(id.c_str());
    entry.name = name;
    entry.func = func;
    IoEntryVec.push_back(entry);
  }
}

const char *FB_getIoEntryNameById(uint8_t i) {
  IoEntry entry = IoEntryVec[i];
  return entry.name.c_str();
}

void FB_addFunctionDB(String key, String type, String action, uint32_t delay,
                      String next) {
  if (FunctionVec.size() < NUM_IO_FUNCTION_MAX) {
    FunctionEntry entry;
    entry.key = key;
    entry.type = atoi(type.c_str());
    entry.action = atoi(action.c_str());
    entry.delay = delay;
    entry.next = next;
    FunctionVec.push_back(entry);
  }
}

uint8_t FB_getIoEntryIdx(String key) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;
  uint8_t res;

  std::string key2 = key.c_str();
  while ((i < IoEntryVec.size()) && (idx == 0xFF)) {
    std::string key1 = IoEntryVec[i].key.c_str();
    res = key1.compare(key2);
    if (res == 0) {
      idx = i;
    }
    i++;
  }

  return idx;
}

uint8_t FB_getFunctionIdx(String key) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;
  uint8_t res;

  std::string key2 = key.c_str();
  while ((i < FunctionVec.size()) && (idx == 0xFF)) {
    std::string key1 = FunctionVec[i].key.c_str();
    res = key1.compare(key2);
    if (res == 0) {
      idx = i;
    }
    i++;
  }

  return idx;
}

void FB_dumpIoEntry(void) {
  Serial.println("FB_dumpIoEntry");
  for (uint8_t i = 0; i < IoEntryVec.size(); ++i) {
    Serial.printf("%d: %06X, %d, %s, %s, %s\n", i, IoEntryVec[i].id,
                  IoEntryVec[i].type, IoEntryVec[i].key.c_str(),
                  IoEntryVec[i].name.c_str(), IoEntryVec[i].func.c_str());
  }
}

void FB_dumpFunctions(void) {
  Serial.println("FB_dumpFunctions");
  for (uint8_t i = 0; i < FunctionVec.size(); ++i) {
    Serial.printf("%d: %s, %s\n", i, FunctionVec[i].key.c_str(),
                  FunctionVec[i].next.c_str());
  }
}
