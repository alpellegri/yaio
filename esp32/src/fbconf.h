#ifndef FBCONF_H
#define FBCONF_H

#include <Arduino.h>

extern String FbGetPath_startup(void);
extern String FbGetPath_control(void);
extern String FbGetPath_status(void);
extern String FbGetPath_exec(void);
extern String FbGetPath_fcmtoken(void);
extern String FbGetPath_data(void);
extern String FbGetPath_message(void);
extern String FbGetPath_log(void);

extern bool FbGetDB(void);

extern void dump_path(void);

#endif
