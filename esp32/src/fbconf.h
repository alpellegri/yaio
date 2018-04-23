#ifndef FBCONF_H
#define FBCONF_H

#include <Arduino.h>

#define kDOut 0
#define kRadioIn 1
#define kLOut 2
#define kDIn 3
#define kRadioOut 4
#define kRadioElem 5
#define kTimer 6

extern String kstartup;
extern String kcontrol;
extern String kstatus;
extern String kfunctions;
extern String kmessaging;
extern String kgraph;
extern String klogs;

void FbconfInit(void);
extern bool FbmUpdateRadioCodes(void);

#endif
