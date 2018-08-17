#ifndef FBM_H
#define FBM_H

#include <Arduino.h>

extern void FbmLogicReq(uint8_t src_idx, uint8_t lin, bool value);
extern bool FBM_monitorActive(void);
extern void FbmService(void);

#endif
