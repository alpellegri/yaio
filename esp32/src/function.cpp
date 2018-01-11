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

typedef struct {
  uint32_t V;
  uint32_t ACC;
} vm_context_t;

typedef struct {
  void (*read)(vm_context_t ctx, String value);
  void (*exec)(vm_context_t ctx, String key_value, String &key);
  void (*write)(vm_context_t ctx, String key_value);
} itlb_t;

void vm_read0(vm_context_t ctx, String value) {
  Serial.printf("vm_read0\n");
  return 0;
}

void vm_readi(vm_context_t ctx, String value) {
  uint32_t v = atoi(value.c_str());
  Serial.printf("vm_readi V=%d, IN=%s\n", v, value.c_str());
  return v;
}

void vm_read24(vm_context_t ctx, String value) {
  uint8_t id = FB_getIoEntryIdx(value);
  uint32_t mask = (1 << 24) - 1;
  uint32_t ctx.V = IoEntryVec[id].value & mask;
  Serial.printf("vm_read24 V=%d, IN=%s, IN=%d\n", ctx.V, value.c_str(),
                IoEntryVec[id].value);
}

void vm_read(vm_context_t ctx, String key_value) {
  uint8_t id = FB_getIoEntryIdx(key_value);
  uint32_t v = IoEntryVec[id].value;
  Serial.printf("vm_read V=%d, IN=%s, IN=%d\n", v, key_value.c_str(), v);
  ctx.V = v;
}

void vm_exec_ex0(vm_context_t ctx, String key_value, String &cb) {
  Serial.printf("vm_exec_ex0\n");
  ctx.ACC = 0;
}

void vm_exec_ldi(vm_context_t ctx, String key_value, String &cb) {
  Serial.printf("vm_exec_ldi ACC=%d, V=%d\n", acc, ctx.V);
  ctx.ACC = ctx.V;
}

void vm_exec_st(vm_context_t ctx, String key_value, String &cb) {
  Serial.printf("vm_exec_st ACC=%d, V=%d\n", acc, ctx.V);
}

void vm_exec_lt(vm_context_t ctx, String key_value, String &cb) {
  ctx.ACC = (ctx.V < ctx.ACC);
}

void vm_exec_gt(vm_context_t ctx, String key_value, String &cb) {
  return ctx.V > acc;
}

void vm_exec_eq(vm_context_t ctx, String key_value, String &cb) {
  Serial.printf("vm_exec_eq ACC=%d, V=%d\n", acc, ctx.V);
  return ctx.V == acc;
}

void vm_exec_bz(vm_context_t ctx, String key_value, String &cb) {
  if (acc == 0) {
    cb == key_value;
  }
  return acc;
}

void vm_exec_bnz(vm_context_t ctx, String key_value, String &cb) {
  if (acc != 0) {
    cb == key_value;
  }
  return acc;
}

void vm_exec_dly(vm_context_t ctx, String key_value, String &cb) {
}

void vm_write0(vm_context_t ctx, String key_value) {
  Serial.printf("vm_write0 ACC=%d\n", acc);
}

void vm_write(vm_context_t ctx, String key_value) {
  Serial.printf("vm_write ACC=%d\n", acc);
  uint8_t id = FB_getIoEntryIdx(key_value);
  IoEntryVec[id].value = acc;
  IoEntryVec[id].wb = true;
}

void vm_write24(vm_context_t ctx, String key_value) {
  Serial.printf("vm_write24 ACC=%d\n", acc);
  uint8_t id = FB_getIoEntryIdx(key_value);
  uint32_t mask = (1 << 24) - 1;
  uint32_t value = (IoEntryVec[id].value & (~mask)) | (acc & mask);
  IoEntryVec[id].value = value;
  IoEntryVec[id].wb = true;
}

itlb_t VM_pipe[] = {
    /*  0: ex0  */ {vm_read0, vm_exec_ex0, vm_write0},
    /*  1: ldi  */ {vm_readi, vm_exec_ldi, vm_write0},
    /*  2: ld24 */ {vm_read24, vm_exec_ldi, vm_write0},
    /*  3: ld   */ {vm_read, vm_exec_ldi, vm_write0},
    /*  4: st24 */ {vm_read0, vm_exec_st, vm_write24},
    /*  5: st   */ {vm_read0, vm_exec_st, vm_write},
    /*  6: lt   */ {vm_read, vm_exec_lt, vm_write0},
    /*  7: gt   */ {vm_read, vm_exec_gt, vm_write0},
    /*  8: eqi  */ {vm_readi, vm_exec_eq, vm_write0},
    /*  9: eq   */ {vm_read, vm_exec_eq, vm_write0},
    /* 10: bz   */ {vm_read0, vm_exec_bz, vm_write0},
    /* 11: bnz  */ {vm_read0, vm_exec_bnz, vm_write0},
    /* 12: dly  */ {vm_read, vm_exec_dly, vm_write0},
};

uint32_t VM_decode(uint32_t ACC, FunctionEntry &stm) {
  uint32_t code = stm.code;
  String &value = stm.value;

  /* decode-read */
  uint32_t V = VM_pipe[code].read(value);

  /* decode-execute */
  String &cb = stm.cb;
  ACC = VM_pipe[code].exec(ACC, V, value, cb);

  /* decode-write */
  VM_pipe[code].write(value, ACC);

  return ACC;
}

void VM_readIn(void) {
  uint32_t value;

  /* loop over data elements looking for events */
  for (uint8_t i = 0; i < IoEntryVec.size(); i++) {
    switch (IoEntryVec[i].code) {
    case kPhyIn: {
      // Serial.printf("VM_readIn-kPhyIn: %s\n", IoEntryVec[i].name.c_str());
      uint8_t pin = IoEntryVec[i].value >> 24;
      pinMode(pin, INPUT);
      uint32_t mask = (1 << 24) - 1;
      value = digitalRead(pin) & mask;
      if ((IoEntryVec[i].value & mask) != value) {
        IoEntryVec[i].value = (IoEntryVec[i].value & (~mask)) | value;
        Serial.printf("VM_readIn: %s, %d, %d\n", IoEntryVec[i].name.c_str(),
                      value, IoEntryVec[i].value);
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
      switch (IoEntryVec[i].code) {
      case kPhyOut: {
        uint32_t mask = (1 << 24) - 1;
        uint8_t pin = IoEntryVec[i].value >> 24;
        pinMode(pin, OUTPUT);
        uint32_t value = IoEntryVec[i].value & mask;
        Serial.printf("VM_writeOut: kPhyOut %d, %d\n", pin, value);
        digitalWrite(pin, value);
        IoEntryVec[i].wb = false;
      } break;
      case kInt: {
        uint32_t value = IoEntryVec[i].value;
        Serial.printf("VM_writeOut: kInt %d\n", value);
        Firebase.setInt(kgraph + "/" + IoEntryVec[i].key + "/value", value);
        if (Firebase.failed() == true) {
          Serial.print(F("set failed: kInt"));
          Serial.println(Firebase.error());
        } else {
          IoEntryVec[i].wb = false;
        }

      } break;
      default:
        // Serial.printf("VM_writeOut: error\n");
        break;
      }
    }
  }
}

void VM_run(void) {
  VM_readIn();
  uint8_t id = VM_findEvent();
  if (id != 0xFF) {
    String key_stm = IoEntryVec[id].cb;
    Serial.printf("VM_run start %s\n", key_stm.c_str());
    uint32_t ACC = 0;
    while (key_stm.length() != 0) {
      /* fetch */
      uint8_t id_stm = FB_getFunctionIdx(key_stm);
      FunctionEntry &stm = FunctionVec[id_stm];
      Serial.printf("VM_run code=%d, ACC=%d\n", stm.code, ACC);
      /* decode */
      ACC = VM_decode(ACC, stm);
      /* key_stm works like a program counter */
      key_stm = stm.cb;
    }
    VM_writeOut();
  }
}
