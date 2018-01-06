#include <Arduino.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>

#include "fbutils.h"

static IoEntry_t *IoEntry = NULL;
static uint8_t IoEntryLen = 0;
static FunctionEntry_t *Function = NULL;
static uint8_t FunctionLen = 0;

void FB_deinitIoEntryDB(void) {
  if (IoEntry != NULL) {
    free(IoEntry);
  }
  IoEntry = NULL;
  IoEntryLen = 0;
}

void FB_deinitFunctionDB(void) {
  if (Function != NULL) {
    free(Function);
  }
  Function = NULL;
  FunctionLen = 0;
}

IoEntry_t *FB_getIoEntry(void) { return IoEntry; }

uint8_t FB_getIoEntryLen(void) { return IoEntryLen; }

FunctionEntry_t *FB_getFunction(void) { return Function; }

uint8_t FB_getFunctionLen(void) { return FunctionLen; }

void FB_initIoEntryDB(uint8_t num) {
  IoEntryLen = 0;
  if (num > 0) {
    IoEntry = (IoEntry_t *)malloc(num * sizeof(IoEntry_t));
  }
}

void FB_initFunctionDB(uint8_t num) {
  FunctionLen = 0;
  if (num > 0) {
    Function = (FunctionEntry_t *)malloc(num * sizeof(FunctionEntry_t));
  }
}

void FB_addIoEntryDB(String key, uint8_t type, String id, String name,
                     String func) {
  if (IoEntryLen < NUM_IO_ENTRY_MAX) {
    strcpy(IoEntry[IoEntryLen].key, key.c_str());
    IoEntry[IoEntryLen].id = atoi(id.c_str());
    IoEntry[IoEntryLen].type = type;
    strcpy(IoEntry[IoEntryLen].name, name.c_str());
    strcpy(IoEntry[IoEntryLen].func, func.c_str());
    IoEntryLen++;
  }
}

void FB_dumpIoEntry(void) {
  Serial.println("FB_dumpIoEntry");
  for (uint8_t i = 0; i < IoEntryLen; i++) {
    Serial.printf("%d: %06X, %d, %s, %s, %s\n", i, IoEntry[i].id,
                  IoEntry[i].type, IoEntry[i].key, IoEntry[i].name,
                  IoEntry[i].func);
  }
}

void FB_dumpFunctions(void) {
  Serial.println("FB_dumpFunctions");
  for (uint8_t i = 0; i < FunctionLen; i++) {
    Serial.printf("%d: %s, %s\n", i, Function[i].key, Function[i].next);
  }
}

char *FB_getIoEntryNameById(uint8_t idx) { return (IoEntry[idx].name); }

void FB_addFunctionDB(String key, String type, String action, uint32_t delay,
                      String next) {
  if (FunctionLen < NUM_IO_FUNCTION_MAX) {
    strcpy(Function[FunctionLen].key, key.c_str());
    Function[FunctionLen].type = atoi(type.c_str());
    strcpy(Function[FunctionLen].action, action.c_str());
    Function[FunctionLen].delay = delay;
    strcpy(Function[FunctionLen].next, next.c_str());
    FunctionLen++;
  }
}

uint8_t FB_getIoEntryIdx(char *key) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;
  uint8_t res;

  while ((i < IoEntryLen) && (idx == 0xFF)) {
    res = strcmp(IoEntry[i].key, key);
    if (res == 0) {
      idx = i;
    }
    i++;
  }

  return idx;
}

uint8_t FB_getFunctionIdx(char *key) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;
  uint8_t res;

  while ((i < FunctionLen) && (idx == 0xFF)) {
    res = strcmp(Function[i].key, key);
    if (res == 0) {
      idx = i;
    }
    i++;
  }

  return idx;
}
