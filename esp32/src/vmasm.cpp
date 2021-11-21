#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "fbutils.h"
#include "vmasm.h"

extern void VM_writeOutMessage(vm_context_t &ctx, String value);

uint8_t vm_exec_nop(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_ex0 value=%s\n", key_value);
  return pc + 1;
}

void vm_readi(vm_context_t &ctx, const char *value) {
  // DEBUG_PRINT("vm_readi value=%s\n", value);
  ctx.V = atoi(value);
}

void vm_read(vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_read value=%s\n", key_value);
  int16_t id = FB_getIoEntryIdx(key_value);
  IoEntry &entry = FB_getIoEntry(id);
  uint32_t v = atoi(entry.value.c_str());
  ctx.V = v;
}

uint8_t vm_exec_ldi(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_ldi value=%s\n", key_value);
  ctx.ACC = ctx.V;
  return pc + 1;
}

uint8_t vm_exec_addi(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_addi value=%s\n", key_value);
  ctx.ACC += ctx.V;
  return pc + 1;
}

uint8_t vm_exec_subi(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_subi value=%s\n", key_value);
  ctx.ACC -= ctx.V;
  return pc + 1;
}

uint8_t vm_exec_st(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_st value=%s\n", key_value);
  return pc + 1;
}

uint8_t vm_exec_lt(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_lt value=%s\n", key_value);
  ctx.ACC = (ctx.ACC < ctx.V);
  return pc + 1;
}

uint8_t vm_exec_lte(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_lte value=%s\n", key_value);
  ctx.ACC = (ctx.ACC <= ctx.V);
  return pc + 1;
}

uint8_t vm_exec_gt(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_gt value=%s\n", key_value);
  ctx.ACC = (ctx.ACC > ctx.V);
  return pc + 1;
}

uint8_t vm_exec_gte(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_gte value=%s\n", key_value);
  ctx.ACC = (ctx.ACC >= ctx.V);
  return pc + 1;
}

uint8_t vm_exec_eqi(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_eq value=%s\n", key_value);
  ctx.ACC = (ctx.ACC == ctx.V);
  return pc + 1;
}

uint8_t vm_exec_bz(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_bz value=%s\n", key_value);
  if (ctx.ACC == 0) {
    return atoi(key_value);
  }
  return pc + 1;
}

uint8_t vm_exec_bnz(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_bnz value=%s\n", key_value);
  if (ctx.ACC != 0) {
    return atoi(key_value);
  }
  return pc + 1;
}

uint8_t vm_exec_jmp(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_jmp value=%s\n", key_value);
  return atoi(key_value);
}

uint8_t vm_exec_dly(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_dly value=%s\n", key_value);
  delay(ctx.ACC);
  return pc + 1;
}

uint8_t vm_exec_halt(uint8_t pc, vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_exec_hlt value=%s\n", key_value);
  ctx.HALT = true;
  return pc;
}

void vm_write(vm_context_t &ctx, const char *key_value) {
  // DEBUG_PRINT("vm_write value=%s\n", key_value);
  int16_t id = FB_getIoEntryIdx(key_value);
  IoEntry &entry = FB_getIoEntry(id);
  if (entry.code == kMessaging) {
    //
    VM_writeOutMessage(ctx, entry.value);
  } else if (entry.code == kTimeout) {
    entry.value = String(ctx.ACC);
    entry.wb = 1;
  } else {
    entry.value = String(ctx.ACC);
    entry.wb = 1;
    entry.ev = true;
  }
}

vm_itlb_t VM_pipe[] = {
    /*  0: nop      */ {"nop", NULL, vm_exec_nop, NULL},
    /*  1: ldi      */ {"ldi", vm_readi, vm_exec_ldi, NULL},
    /*  2: reserved */ {"res2", NULL, NULL, NULL},
    /*  3: ld       */ {"ld", vm_read, vm_exec_ldi, NULL},
    /*  4: reserved */ {"res4", NULL, NULL, NULL},
    /*  5: st       */ {"st", NULL, vm_exec_st, vm_write},
    /*  6: lt       */ {"lt", vm_read, vm_exec_lt, NULL},
    /*  7: gt       */ {"gt", vm_read, vm_exec_gt, NULL},
    /*  8: eqi      */ {"eqi", vm_readi, vm_exec_eqi, NULL},
    /*  9: eq       */ {"eq", vm_read, vm_exec_eqi, NULL},
    /* 10: bz       */ {"bz", NULL, vm_exec_bz, NULL},
    /* 11: bnz      */ {"bnz", NULL, vm_exec_bnz, NULL},
    /* 12: dly      */ {"dly", vm_readi, vm_exec_dly, NULL},
    /* 13: reserved */ {"res13", NULL, NULL, NULL},
    /* 14: lte      */ {"lte", vm_read, vm_exec_lte, NULL},
    /* 15: gte      */ {"gte", vm_read, vm_exec_gte, NULL},
    /* 16: halt     */ {"halt", NULL, vm_exec_halt, NULL},
    /* 17: jmp      */ {"jmp", NULL, vm_exec_jmp, NULL},
    /* 18: addi     */ {"addi", vm_readi, vm_exec_addi, NULL},
    /* 19: add      */ {"add", vm_read, vm_exec_addi, NULL},
    /* 20: subi     */ {"subi", vm_readi, vm_exec_subi, NULL},
    /* 21: sub      */ {"sub", vm_read, vm_exec_subi, NULL},
};

uint8_t VM_decode(uint8_t pc, vm_context_t &ctx, FuncEntry &stm) {
  uint32_t code = stm.code;
  String &value = stm.value;

  if (code < (sizeof(VM_pipe) / sizeof(vm_itlb_t))) {
    /* decode-read */
    // DEBUG_PRINT("VM_pipe read\n");
    if (VM_pipe[code].read != NULL) {
      VM_pipe[code].read(ctx, value.c_str());
      // DEBUG_PRINT("asm-r: %s %s ACC=%d V=%d\n", VM_pipe[code].opcode,
      //             value.c_str(), ctx.ACC, ctx.V);
    }

    /* decode-execute */
    // DEBUG_PRINT("VM_pipe exec\n");
    if (VM_pipe[code].exec != NULL) {
      pc = VM_pipe[code].exec(pc, ctx, value.c_str());
      DEBUG_PRINT("asm: %s %s %d\n", VM_pipe[code].opcode, value.c_str(),
                  ctx.ACC);
    }

    /* decode-write */
    // DEBUG_PRINT("VM_pipe write\n");
    if (VM_pipe[code].write != NULL) {
      VM_pipe[code].write(ctx, value.c_str());
      // DEBUG_PRINT("asm-w: %s %s ACC=%d V=%d\n", VM_pipe[code].opcode,
      //             value.c_str(), ctx.ACC, ctx.V);
    }
  } else {
    ctx.HALT = true;
  }

  return pc;
}
