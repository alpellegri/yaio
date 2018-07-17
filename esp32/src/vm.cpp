#include <Arduino.h>
#include <Ticker.h>

#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "fbconf.h"
#include "fblog.h"
#include "fbm.h"
#include "fbutils.h"
#include "firebase.h"
#include "pht.h"
#include "rf.h"
#include "timers.h"
#include "timesrv.h"

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
  for (uint8_t id = 0; id < FB_getIoEntryLen(); id++) {
    IoEntry &entry = FB_getIoEntry(id);
    switch (entry.code) {
    case kPhyIn: {
      uint32_t v = atoi(entry.value.c_str());
      uint8_t pin = entry.ioctl;
      pinMode(pin, INPUT);
      uint32_t value = digitalRead(pin);
      if (v != value) {
        DEBUG_PRINT("VM_readIn: %s, %d, %s\n", entry.key.c_str(), value, v);
        entry.value = value;
        entry.ev = true;
        entry.ev_value = value;
        entry.wb = true;
      }
    } break;
    case kPhyOut: {
      if (VM_UpdateDataPending == true) {
        DEBUG_PRINT("get: kPhyOut\n");
        String kdata;
        FbSetPath_data(kdata);
        uint32_t value = Firebase.getInt(kdata + "/" + entry.key + "/value");
        if (Firebase.failed() == true) {
          DEBUG_PRINT("get failed: kPhyOut %s\n", entry.key.c_str());
        } else {
          uint32_t v = atoi(entry.value.c_str());
          if (v != value) {
            DEBUG_PRINT("VM_readIn: %s, %d, %s\n", entry.key.c_str(), value, v);
            entry.value = value;
            entry.ev = true;
            entry.ev_value = value;
            entry.wb = true;
          }
        }
      }
    } break;
    case kDhtTemperature: {
      uint32_t v = atoi(entry.value.c_str());
      uint32_t value = PHT_GetTemperature();
      if (v != value) {
        DEBUG_PRINT("VM_readIn: %s, %d, %s\n", entry.key.c_str(), value, v);
        entry.value = value;
        entry.ev = true;
        entry.ev_value = value;
        entry.wb = true;
      }
    } break;
    case kDhtHumidity: {
      uint32_t v = atoi(entry.value.c_str());
      uint32_t value = PHT_GetHumidity();
      if (v != value) {
        DEBUG_PRINT("VM_readIn: %s, %d, %s\n", entry.key.c_str(), value, v);
        entry.value = value;
        entry.ev = true;
        entry.ev_value = value;
        entry.wb = true;
      }
    } break;
    case kRadioRx: {
      uint32_t v = atoi(entry.value.c_str());
      uint32_t value = RF_GetRadioCode();
      if (v != value) {
        DEBUG_PRINT("VM_readIn: %s, %d, %s\n", entry.key.c_str(), value, v);
        entry.value = value;
        entry.ev = true;
        entry.ev_value = value;
        entry.wb = true;
      }
    } break;
    case kBool: {
      if (VM_UpdateDataPending == true) {
        DEBUG_PRINT("get: kBool\n");
        String kdata;
        FbSetPath_data(kdata);
        bool value = Firebase.getBool(kdata + "/" + entry.key + "/value");
        if (Firebase.failed() == true) {
          DEBUG_PRINT("get failed: kBool %s\n", entry.key.c_str());
          UpdateDataFault = true;
        } else {
          uint32_t v = atoi(entry.value.c_str());
          if (v != value) {
            DEBUG_PRINT("VM_readIn: %s, %d\n", entry.key.c_str(), value);
            entry.value = value;
            entry.ev = true;
            entry.ev_value = value;
          }
        }
      }
    } break;
    case kInt: {
      if (VM_UpdateDataPending == true) {
        DEBUG_PRINT("get: kInt\n");
        String kdata;
        FbSetPath_data(kdata);
        uint32_t value = Firebase.getInt(kdata + "/" + entry.key + "/value");
        if (Firebase.failed() == true) {
          DEBUG_PRINT("get failed: kInt %s\n", entry.key.c_str());
          UpdateDataFault = true;
        } else {
          uint32_t v = atoi(entry.value.c_str());
          if (v != value) {
            DEBUG_PRINT("VM_readIn: %s, %d\n", entry.key.c_str(), value);
            entry.value = value;
            entry.ev = true;
            entry.ev_value = value;
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
  while ((i < FB_getIoEntryLen()) && (idx == 0xFF)) {
    IoEntry &entry = FB_getIoEntry(i);
    if (entry.ev == true) {
      // DEBUG_PRINT("VM_findEvent found: %d\n", i);
      entry.ev = false;
      *ev_value = entry.ev_value;
      idx = i;
    }
    i++;
  }

  return idx;
}

void VM_writeOutMessage(vm_context_t &ctx, String value) {
  DEBUG_PRINT("VM_writeOutMessage: %s\n", value.c_str());
  String message = value + " " + ctx.ev_name;
  fblog_log(message, true);
}

void VM_writeOut(void) {
  /* loop over data elements looking for write-back requests */
  for (uint8_t i = 0; i < FB_getIoEntryLen(); i++) {
    IoEntry &entry = FB_getIoEntry(i);
    if (entry.wb == true) {
      switch (entry.code) {
      case kPhyOut: {
        uint32_t v = atoi(entry.value.c_str());
        uint8_t pin = entry.ioctl;
        pinMode(pin, OUTPUT);
        digitalWrite(pin, v);
        entry.wb = false;
      } break;
      case kPhyIn:
      case kDhtTemperature:
      case kDhtHumidity:
      case kRadioIn:
      case kRadioRx:
      case kInt: {
        uint32_t value = atoi(entry.value.c_str());
        DEBUG_PRINT("VM_writeOut: %s: %d\n", entry.key.c_str(), value);
        String ref;
        FbSetPath_data(ref);
        Firebase.setInt(ref + "/" + entry.key + "/value", value);
        if (Firebase.failed() == true) {
          DEBUG_PRINT("Firebase set failed: VM_writeOut %s\n",
                      entry.key.c_str());
        } else {
          if (entry.enLog == true) {
            DynamicJsonBuffer jsonBuffer;
            JsonObject &json = jsonBuffer.createObject();
            json["t"] = getTime();
            json["v"] = value;
            String strdata;
            json.printTo(strdata);
            FbSetPath_log(ref);
            Firebase.pushJSON(ref + "/" + entry.key, strdata);
            if (Firebase.failed() == true) {
              DEBUG_PRINT("Firebase push failed: VM_writeOut %s\n",
                          entry.key.c_str());
            } else {
              entry.wb = false;
            }
          } else {
            entry.wb = false;
          }
        }
      } break;
      case kBool: {
        bool value = atoi(entry.value.c_str());
        DEBUG_PRINT("VM_writeOut: kBool %d\n", value);
        String ref;
        FbSetPath_data(ref);
        Firebase.setBool(ref + "/" + entry.key + "/value", value);
        if (Firebase.failed() == true) {
          DEBUG_PRINT("Firebase set failed: VM_writeOut %s\n",
                      entry.key.c_str());
        } else {
          entry.wb = false;
        }
      } break;
      case kMessaging: {
        DEBUG_PRINT("VM_writeOut: kMessaging %s\n", entry.value.c_str());
        fblog_log(entry.value, true);
        entry.wb = false;
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
  IoEntry &entry = FB_getIoEntry(id);
  uint32_t v = atoi(entry.value.c_str());
  ctx.V = v & mask;
}

void vm_read(vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_read value=%s\n", key_value);
  uint8_t id = FB_getIoEntryIdx(key_value);
  IoEntry &entry = FB_getIoEntry(id);
  uint32_t v = atoi(entry.value.c_str());
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
  IoEntry &entry = FB_getIoEntry(id);
  if (entry.code == kMessaging) {
    /**/
    VM_writeOutMessage(ctx, entry.value);
  } else {
    entry.value = ctx.ACC;
    entry.wb = true;
  }
}

void vm_cwrite(vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_cwrite value=%s\n", key_value);
  uint8_t id = FB_getIoEntryIdx(key_value);
  IoEntry &entry = FB_getIoEntry(id);
  uint32_t v = atoi(entry.value.c_str());
  if ((ctx.cond == true) && (v != ctx.ACC)) {
    ctx.cond = false;
    entry.value = ctx.ACC;
    entry.wb = true;
  }
}

void vm_write24(vm_context_t &ctx, const char *key_value) {
  DEBUG_PRINT("vm_write24 value=%s\n", key_value);
  uint8_t id = FB_getIoEntryIdx(key_value);
  uint32_t mask = (1 << 24) - 1;
  IoEntry &entry = FB_getIoEntry(id);
  uint32_t v = atoi(entry.value.c_str());
  uint32_t value = (v & (~mask)) | (ctx.ACC & mask);
  entry.value = value;
  entry.wb = true;
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
    IoEntry &entry = FB_getIoEntry(id);
    String key = entry.cb;

    vm_context_t ctx;
    ctx.V = 0;
    /* init ACC with event value */
    ctx.ACC = ev_value;
    ctx.halt = false;

    /* keep the event name */
    ctx.ev_name = entry.key.c_str();
    DEBUG_PRINT("VM_run start >>>>>>>>>>>>\n");
    DEBUG_PRINT("Heap: %d\n", ESP.getFreeHeap());
    if (key.length() != 0) {
      uint8_t id_prog = FB_getProgIdx(key.c_str());
      ProgEntry &prog = FB_getProg(id_prog);
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
