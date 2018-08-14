#ifndef VMASM_H
#define VMASM_H

#include <Arduino.h>

#include "fbutils.h"

typedef struct {
  int32_t V;
  int32_t ACC;
  bool HALT;
  const char *ev_name;
} vm_context_t;

typedef struct {
  void (*read)(vm_context_t &ctx, const char *value);
  uint8_t (*exec)(uint8_t pc, vm_context_t &ctx, const char *key_value);
  void (*write)(vm_context_t &ctx, const char *key_value);
} vm_itlb_t;

extern uint8_t VM_decode(uint8_t pc, vm_context_t &ctx, FuncEntry &stm);

#endif
