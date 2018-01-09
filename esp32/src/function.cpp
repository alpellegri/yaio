#include <Arduino.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>
#include <vector>

#include "fbconf.h"
#include "fbm.h"
#include "fbutils.h"
#include "rf.h"
#include <FirebaseArduino.h>

extern std::vector<IoEntry> IoEntryVec;
extern std::vector<FunctionEntry> FunctionVec;

void VM_readIn(void) {
  uint32_t value;

  /* loop over data elements looking for events */
  for (uint8_t i = 0; i < IoEntryVec.size(); i++) {
    switch (IoEntryVec[i].code) {
    case kPhyIn: {
      Serial.printf("VM_readIn-kPhyIn: %s\n", IoEntryVec[i].name.c_str());
      uint8_t pin = IoEntryVec[i].value >> 24;
      pinMode(pin, INPUT);
      uint32_t mask = (1 << 24) - 1;
      value = digitalRead(pin) & mask;
      if ((IoEntryVec[i].value & mask) != value) {
        IoEntryVec[i].value = (IoEntryVec[i].value & (~mask)) | value;
        IoEntryVec[i].ev = true;
      }
    } break;
    case kInt: {
      value = Firebase.getInt(kgraph + "/" + IoEntryVec[i].key + "/value");
      if (Firebase.failed() == true) {
        Serial.print(F("get failed: kInt"));
        Serial.println(Firebase.error());
      } else {
        if ((IoEntryVec[i].value) != value) {
          IoEntryVec[i].value = value;
          IoEntryVec[i].ev = true;
        }
      }
    } break;
    default:
      // Serial.printf("VM_readIn: error\n");
      break;
    }
  }
}

uint8_t VM_findEvent(void) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;
  /* loop over data elements looking for events */
  while ((i < IoEntryVec.size()) && (idx == 0xFF)) {
    if (IoEntryVec[i].ev == true) {
      IoEntryVec[i].ev = false;
      idx = i;
    }
    i++;
  }

  return idx;
}

void VM_writeOut(void) {
  /* loop over data elements looking for write-back requests */
  for (uint8_t i = 0; i < IoEntryVec.size(); i++) {
    if (IoEntryVec[i].wb == true) {
      IoEntryVec[i].wb = false;
    }
    if (IoEntryVec[i].code == kPhyOut) {
      uint8_t pin = IoEntryVec[i].value >> 24;
      pinMode(pin, OUTPUT);
      digitalWrite(pin, IoEntryVec[i].value);
    }
  }
}

typedef struct {
  uint32_t (*read)(String value);
  uint32_t (*exec)(uint32_t acc, uint32_t v, String key_value, String &key);
  void (*write)(String key_value, uint32_t acc);
} itlb_t;

uint32_t vm_read0(String value) { return 0; }

uint32_t vm_readi(String value) { return atoi(value.c_str()); }

uint32_t vm_read24(String value) { return atoi(value.c_str()) & (1 << 24 - 1); }

uint32_t vm_read(String key_value) {
  uint8_t id = FB_getIoEntryIdx(key_value);
  return IoEntryVec[id].value;
}

uint32_t vm_exec_ex0(uint32_t acc, uint32_t v, String key_value, String &cb) {
  return 0;
}

uint32_t vm_exec_ldi(uint32_t acc, uint32_t v, String key_value, String &cb) {
  return v;
}

uint32_t vm_exec_st(uint32_t acc, uint32_t v, String key_value, String &cb) {
  return acc;
}

uint32_t vm_exec_lt(uint32_t acc, uint32_t v, String key_value, String &cb) {
  return v < acc;
}

uint32_t vm_exec_gt(uint32_t acc, uint32_t v, String key_value, String &cb) {
  return v > acc;
}

uint32_t vm_exec_eq(uint32_t acc, uint32_t v, String key_value, String &cb) {
  return v == acc;
}

uint32_t vm_exec_bz(uint32_t acc, uint32_t v, String key_value, String &cb) {
  if (acc == 0) {
    cb == key_value;
  }
  return acc;
}

uint32_t vm_exec_bnz(uint32_t acc, uint32_t v, String key_value, String &cb) {
  if (acc != 0) {
    cb == key_value;
  }
  return acc;
}

uint32_t vm_exec_dly(uint32_t acc, uint32_t v, String key_value, String &cb) {
  return acc;
}

void vm_write0(String key_value, uint32_t acc) {}

void vm_write(String key_value, uint32_t acc) {
  uint8_t id = FB_getIoEntryIdx(key_value);
  IoEntryVec[id].value = acc;
}

void vm_write24(String key_value, uint32_t acc) {
  uint8_t id = FB_getIoEntryIdx(key_value);
  uint32_t mask = (1 << 24) - 1;
  IoEntryVec[id].value = (IoEntryVec[id].value & (~mask)) | (acc & mask);
}

itlb_t VM_itlb[] = {
    /* ex0  */ {vm_read0, vm_exec_ex0, vm_write0},
    /* ldi  */ {vm_readi, vm_exec_ldi, vm_write0},
    /* ld24 */ {vm_read24, vm_exec_ldi, vm_write0},
    /* ld   */ {vm_read, vm_exec_ldi, vm_write0},
    /* st24 */ {vm_read0, vm_exec_st, vm_write24},
    /* st   */ {vm_read0, vm_exec_st, vm_write},
    /* lt   */ {vm_read, vm_exec_lt, vm_write0},
    /* gt   */ {vm_read, vm_exec_gt, vm_write0},
    /* eqi  */ {vm_readi, vm_exec_eq, vm_write0},
    /* eq   */ {vm_read, vm_exec_eq, vm_write0},
    /* bz   */ {vm_read0, vm_exec_bz, vm_write0},
    /* bnz  */ {vm_read0, vm_exec_bnz, vm_write0},
    /* dly  */ {vm_read, vm_exec_dly, vm_write0},
};

uint32_t VM_decode(uint32_t ACC, FunctionEntry &stm) {
  uint32_t code = stm.code;
  String& value = stm.value;

  /* decode-read */
  uint32_t V = VM_itlb[code].read(value);

  /* decode-execute */
  String& cb = stm.cb;
  ACC = VM_itlb[code].exec(ACC, V, value, cb);

  /* decode-write */
  VM_itlb[code].write(value, ACC);

  return ACC;
}

void VM_run(void) {
  VM_readIn();
  uint8_t id = VM_findEvent();
  if (id != 0xFF) {
    Serial.printf("VM_run event: %d\n", id);
    String key_stm = IoEntryVec[id].cb;
    uint32_t ACC = 0;
    while (key_stm.length() != 0) {
      /* fetch */
      uint8_t id_stm = FB_getFunctionIdx(key_stm);
      FunctionEntry &stm = FunctionVec[id_stm];
      /* decode */
      ACC = VM_decode(ACC, stm);
      /* key_stm works like a program counter */
      key_stm = stm.cb;
    }
    VM_writeOut();
  }
}
