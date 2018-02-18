#include <Arduino.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>

#include "fbconf.h"
#include "fblog.h"
#include "fbm.h"
#include "fbutils.h"
#include "firebase.h"
#include "pht.h"
#include "rf.h"
#include "timers.h"

#define DEBUG_PRINT(fmt, ...) Serial.printf_P(PSTR(fmt), ##__VA_ARGS__)

typedef struct {
  bool cond;
  uint32_t V;
  uint32_t ACC;
  bool halt;
  const char *ev_name;
} vm_context_t;

typedef struct {
  void (*read)(vm_context_t &ctx, const char *value);
  uint8_t (*exec)(uint8_t pc, vm_context_t &ctx, const char *key_value);
  void (*write)(vm_context_t &ctx, const char *key_value);
} vm_itlb_t;

bool VM_UpdateDataPending;
void VM_UpdateDataReq(void) { VM_UpdateDataPending = true; }

void VM_readIn(void) {
  RF_Service();
  PHT_Service();
  Timers_Service();
  bool UpdateDataFault = false;

  /* loop over data elements looking for events */
  for (uint8_t i = 0; i < IoEntryVec.size(); i++) {
    switch (IoEntryVec[i].code) {
    case kPhyIn: {
      // DEBUG_PRINT("VM_readIn-kPhyIn: %s\n", IoEntryVec[i].name.c_str());
      uint32_t v = atoi(IoEntryVec[i].value.c_str());
      uint8_t pin = v >> 24;
      pinMode(pin, INPUT);
      uint32_t mask = (1 << 24) - 1;
      uint32_t value = digitalRead(pin) & mask;
      if ((v & mask) != value) {
        value |= (v & (~mask));
        DEBUG_PRINT("VM_readIn: %s, %d, %s\n", IoEntryVec[i].key.c_str(), value,
                    IoEntryVec[i].value.c_str());
        IoEntryVec[i].value = value;
        IoEntryVec[i].ev = true;
        IoEntryVec[i].ev_value = value;
      }
    } break;
    case kDhtTemperature: {
      uint32_t v = atoi(IoEntryVec[i].value.c_str());
      uint32_t mask = (((1 << 16) - 1) << 16);
      uint32_t value = PHT_GetTemperature();
      if ((v & ~mask) != value) {
        value |= (v & mask);
        DEBUG_PRINT("VM_readIn: %s, %d, %s\n", IoEntryVec[i].key.c_str(), value,
                    IoEntryVec[i].value.c_str());
        IoEntryVec[i].value = value;
        IoEntryVec[i].ev = true;
        IoEntryVec[i].ev_value = value;
        IoEntryVec[i].wb = true;
      }
    } break;
    case kDhtHumidity: {
      uint32_t v = atoi(IoEntryVec[i].value.c_str());
      uint32_t mask = (((1 << 16) - 1) << 16);
      uint32_t value = PHT_GetHumidity();
      if ((v & ~mask) != value) {
        value |= (v & mask);
        DEBUG_PRINT("VM_readIn: %s, %d, %s\n", IoEntryVec[i].key.c_str(), value,
                    IoEntryVec[i].value.c_str());
        IoEntryVec[i].value = value;
        IoEntryVec[i].ev = true;
        IoEntryVec[i].ev_value = value;
        IoEntryVec[i].wb = true;
      }
    } break;
    case kRadioRx: {
    } break;
    case kBool: {
      // DEBUG_PRINT("VM_UpdateDataPending %d\n", VM_UpdateDataPending);
      if (VM_UpdateDataPending == true) {
        DEBUG_PRINT("get: kBool\n");
        String kdata;
        FbSetPath_data(kdata);
        bool value =
            Firebase.getBool(kdata + "/" + IoEntryVec[i].key + "/value");
        if (Firebase.failed() == true) {
          DEBUG_PRINT("get failed: kBool %s\n", IoEntryVec[i].key.c_str());
          UpdateDataFault = true;
        } else {
          uint32_t v = atoi(IoEntryVec[i].value.c_str());
          if (v != value) {
            DEBUG_PRINT("VM_readIn: %s, %d\n", IoEntryVec[i].key.c_str(),
                        value);
            IoEntryVec[i].value = value;
            IoEntryVec[i].ev = true;
            IoEntryVec[i].ev_value = value;
          }
        }
      }
    } break;
    case kInt: {
      // DEBUG_PRINT("VM_UpdateDataPending %d\n", VM_UpdateDataPending);
      if (VM_UpdateDataPending == true) {
        DEBUG_PRINT("get: kInt\n");
        String kdata;
        FbSetPath_data(kdata);
        uint32_t value =
            Firebase.getInt(kdata + "/" + IoEntryVec[i].key + "/value");
        if (Firebase.failed() == true) {
          DEBUG_PRINT("get failed: kInt %s\n", IoEntryVec[i].key.c_str());
          UpdateDataFault = true;
        } else {
          uint32_t v = atoi(IoEntryVec[i].value.c_str());
          if (v != value) {
            DEBUG_PRINT("VM_readIn: %s, %d\n", IoEntryVec[i].key.c_str(),
                        value);
            IoEntryVec[i].value = value;
            IoEntryVec[i].ev = true;
            IoEntryVec[i].ev_value = value;
          }
        }
      }
    } break;
    default:
      // DEBUG_PRINT("VM_readIn: error\n");
      break;
    }
  }
  VM_UpdateDataPending = UpdateDataFault;
}

uint8_t VM_findEvent(uint32_t *ev_value) {
  uint8_t i = 0;
  uint8_t idx = 0xFF;
  /* loop over data elements looking for events */
  while ((i < IoEntryVec.size()) && (idx == 0xFF)) {
    if (IoEntryVec[i].ev == true) {
      IoEntryVec[i].ev = false;
      *ev_value = IoEntryVec[i].ev_value;
      idx = i;
    }
    i++;
  }

  return idx;
}

void VM_writeOutPhyOut(uint32_t value) {
  uint32_t mask = (1 << 24) - 1;
  uint8_t pin = value >> 24;
  value &= mask;
  value = !!value;
  DEBUG_PRINT("VM_writeOutPhyOut: %d, %d\n", pin, value);
  pinMode(pin, OUTPUT);
  digitalWrite(pin, value);
}

void VM_writeOutMessage(vm_context_t &ctx, String value) {
  DEBUG_PRINT("VM_writeOutMessage: %s\n", value.c_str());
  String message = value + " " + ctx.ev_name;
  fblog_log(message, true);
}

void VM_writeOut(void) {
  /* loop over data elements looking for write-back requests */
  for (uint8_t i = 0; i < IoEntryVec.size(); i++) {
    if (IoEntryVec[i].wb == true) {
      switch (IoEntryVec[i].code) {
      case kPhyOut: {
        DEBUG_PRINT("VM_writeOut: kPhyOut error\n");
      } break;
      case kDhtTemperature: {
        uint32_t value = atoi(IoEntryVec[i].value.c_str());
        DEBUG_PRINT("VM_writeOut: kDhtTemperature %d\n", value);
        String kdata;
        FbSetPath_data(kdata);
        Firebase.setInt(kdata + "/" + IoEntryVec[i].key + "/value", value);
        if (Firebase.failed() == true) {
          DEBUG_PRINT("set failed: kDhtTemperature\n");
        } else {
          IoEntryVec[i].wb = false;
        }
      } break;
      case kDhtHumidity: {
        uint32_t value = atoi(IoEntryVec[i].value.c_str());
        DEBUG_PRINT("VM_writeOut: kDhtHumidity %d\n", value);
        String kdata;
        FbSetPath_data(kdata);
        Firebase.setInt(kdata + "/" + IoEntryVec[i].key + "/value", value);
        if (Firebase.failed() == true) {
          DEBUG_PRINT("set failed: kDhtHumidity\n");
        } else {
          IoEntryVec[i].wb = false;
        }
      } break;
      case kBool: {
        bool value = atoi(IoEntryVec[i].value.c_str());
        DEBUG_PRINT("VM_writeOut: kBool %d\n", value);
        String kdata;
        FbSetPath_data(kdata);
        Firebase.setBool(kdata + "/" + IoEntryVec[i].key + "/value", value);
        if (Firebase.failed() == true) {
          DEBUG_PRINT("set failed: kBool\n");
        } else {
          IoEntryVec[i].wb = false;
        }
      } break;
      case kInt: {
        uint32_t value = atoi(IoEntryVec[i].value.c_str());
        DEBUG_PRINT("VM_writeOut: kInt %d\n", value);
        String kdata;
        FbSetPath_data(kdata);
        Firebase.setInt(kdata + "/" + IoEntryVec[i].key + "/value", value);
        if (Firebase.failed() == true) {
          DEBUG_PRINT("set failed: kInt\n");
        } else {
          IoEntryVec[i].wb = false;
        }
      } break;
      case kMessaging: {
        // DEBUG_PRINT("VM_writeOut: kMessaging %s\n",
        IoEntryVec[i].value.c_str();
        fblog_log(IoEntryVec[i].value, true);
        IoEntryVec[i].wb = false;
      } break;
      default:
        // DEBUG_PRINT("VM_writeOut: error\n");
        break;
      }
    }
  }
}

void vm_read0(vm_context_t &ctx, const char *value) {
  DEBUG_PRINT("vm_read0 value=%s\n", value);
}

void vm_readi(vm_context_t &ctx, const char *value) {
  DEBUG_PRINT("vm_readi value=%s\n", value);
  ctx.V = atoi(value);
}

void vm_read24(vm_context_t &ctx, const char *value) {
  DEBUG_PRINT("vm_readi24 value=%s\n", value);
  uint8_t id = FB_getIoEntryIdx(value);
  uint32_t mask = (1 << 24) - 1;
  uint32_t v = atoi(IoEntryVec[id].value.c_str());
  ctx.V = v & mask;
}

void vm_read(vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_read value=%s\n", key_value);
  uint8_t id = FB_getIoEntryIdx(key_value);
  uint32_t v = atoi(IoEntryVec[id].value.c_str());
  ctx.V = v;
}

uint8_t vm_exec_ex0(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_ex0 value=%s\n", key_value);
  ctx.ACC = 0;
  return pc + 1;
}

uint8_t vm_exec_ldi(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_ldi value=%s\n", key_value);
  ctx.ACC = ctx.V;
  return pc + 1;
}

uint8_t vm_exec_st(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_st value=%s\n", key_value);
  return pc + 1;
}

uint8_t vm_exec_stne(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_stne value=%s\n", key_value);
  ctx.cond = true;
  return pc + 1;
}

uint8_t vm_exec_lt(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_lt value=%s\n", key_value);
  ctx.ACC = (ctx.ACC < ctx.V);
  return pc + 1;
}

uint8_t vm_exec_lte(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_lt value=%s\n", key_value);
  ctx.ACC = (ctx.ACC < ctx.V);
  return pc + 1;
}

uint8_t vm_exec_gt(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_gt value=%s\n", key_value);
  ctx.ACC = (ctx.ACC > ctx.V);
  return pc + 1;
}

uint8_t vm_exec_gte(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_gt value=%s\n", key_value);
  ctx.ACC = (ctx.ACC > ctx.V);
  return pc + 1;
}

uint8_t vm_exec_eq(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_eq value=%s\n", key_value);
  ctx.ACC = (ctx.ACC == ctx.V);
  return pc + 1;
}

uint8_t vm_exec_bz(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_bz value=%s\n", key_value);
  if (ctx.ACC == 0) {
    return atoi(key_value);
  }
  return pc + 1;
}

uint8_t vm_exec_bnz(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_bnz value=%s\n", key_value);
  if (ctx.ACC != 0) {
    return atoi(key_value);
  }
  return pc + 1;
}

uint8_t vm_exec_jmp(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_jmp value=%s\n", key_value);
  return atoi(key_value);
}

uint8_t vm_exec_dly(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_dly value=%s\n", key_value);
  delay(ctx.ACC);
  return pc + 1;
}

uint8_t vm_exec_halt(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_exec_hlt value=%s\n", key_value);
  ctx.halt = true;
  return pc;
}

void vm_write0(vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_write0 value=%s\n", key_value);
}

void vm_write(vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_write value=%s\n", key_value);
  uint8_t id = FB_getIoEntryIdx(key_value);
  if (IoEntryVec[id].code == kMessaging) {
    /**/
    VM_writeOutMessage(ctx, IoEntryVec[id].value);
  } else {
    IoEntryVec[id].value = ctx.ACC;
    IoEntryVec[id].wb = true;
  }
}

void vm_cwrite(vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_cwrite value=%s\n", key_value);
  uint8_t id = FB_getIoEntryIdx(key_value);
  uint32_t v = atoi(IoEntryVec[id].value.c_str());
  if ((ctx.cond == true) && (v != ctx.ACC)) {
    ctx.cond = false;
    IoEntryVec[id].value = ctx.ACC;
    IoEntryVec[id].wb = true;
  }
}

void vm_write24(vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_write24 value=%s\n", key_value);
  uint8_t id = FB_getIoEntryIdx(key_value);
  uint32_t mask = (1 << 24) - 1;
  uint32_t v = atoi(IoEntryVec[id].value.c_str());
  uint32_t value = (v & (~mask)) | (ctx.ACC & mask);
  if (IoEntryVec[id].code == kPhyOut) {
    VM_writeOutPhyOut(value);
  } else {
    IoEntryVec[id].value = value;
    IoEntryVec[id].wb = true;
  }
}

vm_itlb_t VM_pipe[] = {
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
    /* 12: dly  */ {vm_readi, vm_exec_dly, vm_write0},
    /* 13: stne */ {vm_read0, vm_exec_stne, vm_cwrite},
    /* 14: lte  */ {vm_read, vm_exec_lte, vm_write0},
    /* 15: gte  */ {vm_read, vm_exec_gte, vm_write0},
    /* 16: halt */ {vm_read0, vm_exec_halt, vm_write0},
    /* 17: jmp  */ {vm_read0, vm_exec_jmp, vm_write0},
};

uint8_t VM_decode(uint8_t pc, vm_context_t &ctx, FuncEntry &stm) {
  uint32_t code = stm.code;
  String &value = stm.value;

  /* decode-read */
  DEBUG_PRINT("VM_pipe read\n");
  VM_pipe[code].read(ctx, value.c_str());
  DEBUG_PRINT("VM_decode ACC=%d V=%d\n", ctx.ACC, ctx.V);

  /* decode-execute */
  DEBUG_PRINT("VM_pipe exec\n");
  pc = VM_pipe[code].exec(pc, ctx, value.c_str());
  DEBUG_PRINT("VM_decode ACC=%d V=%d\n", ctx.ACC, ctx.V);

  /* decode-write */
  DEBUG_PRINT("VM_pipe write\n");
  VM_pipe[code].write(ctx, value.c_str());
  DEBUG_PRINT("VM_decode ACC=%d V=%d\n", ctx.ACC, ctx.V);

  return pc;
}

void VM_run(void) {
  VM_readIn();
  uint32_t ev_value;
  uint8_t id = VM_findEvent(&ev_value);
  if (id != 0xFF) {
    String key = IoEntryVec[id].cb;

    vm_context_t ctx;
    ctx.V = 0;
    /* init ACC with event value */
    ctx.ACC = ev_value;
    ctx.halt = false;

    /* keep the event name */
    ctx.ev_name = IoEntryVec[id].key.c_str();
    DEBUG_PRINT("VM_run start >>>>>>>>>>>>\n");
    DEBUG_PRINT("Heap: %d\n", ESP.getFreeHeap());
    if (key.length() != 0) {
      uint8_t id_prog = FB_getProgIdx(key.c_str());
      ProgEntry &prog = ProgVec[id_prog];
      std::vector<FuncEntry> &funcvec = prog.funcvec;

      uint8_t pc = 0;
      while (pc < funcvec.size()) {
        DEBUG_PRINT("VM_run start [%d] code=%d, ACC=%d V=%d\n", pc,
                    funcvec[pc].code, ctx.ACC, ctx.V);
        /* decode */
        pc = VM_decode(pc, ctx, funcvec[pc]);

        DEBUG_PRINT("VM_run stop [%d] code=%d, ACC=%d V=%d\n", pc,
                    funcvec[pc].code, ctx.ACC, ctx.V);
      }
    }
    VM_writeOut();
    DEBUG_PRINT("VM_run stop <<<<<<<<<<<<<\n");
  }
}
