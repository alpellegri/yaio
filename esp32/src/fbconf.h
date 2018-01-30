#ifndef FBCONF_H
#define FBCONF_H

#include <Arduino.h>

extern void FbSetPath_startup(String &path);
extern void FbSetPath_control(String &path);
extern void FbSetPath_status(String &path);
extern void FbSetPath_exec(String &path);
extern void FbSetPath_fcmtoken(String &path);
extern void FbSetPath_data(String &path);
extern void FbSetPath_logs(String &path);
extern bool FbmUpdateRadioCodes(void);

extern void dump_path(void);

#endif
