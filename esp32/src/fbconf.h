#ifndef FBCONF_H
#define FBCONF_H

#include <Arduino.h>

extern String kstartup;
extern String kcontrol;
extern String kstatus;
extern String kfcmtoken;
extern String kdata;
extern String kexec;
extern String klogs;

void FbconfInit(void);
extern bool FbmUpdateRadioCodes(void);

#endif
