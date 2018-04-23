#ifndef VM_H
#define VM_H

#include <Arduino.h>

// extern void FunctionReq(uint8_t src_idx, String key);
extern void VM_run(void);
extern void VM_UpdateDataReq(void);

#endif
