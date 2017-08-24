#ifndef FBM_H
#define FBM_H

#include <Arduino.h>

extern void FbmReqFunction(uint8_t src_type, uint8_t src_idx, uint8_t lin,
                           bool value);
extern bool FbmService(void);

#endif
