#include <Arduino.h>

#include "vers.h"

static const char build_str[] PROGMEM =
    "HW:[" VERS_HW_VER "] - SW:[" VERS_SW_VER "] | " __DATE__ " " __TIME__;

String VERS_getVersion(void) { return FPSTR(build_str); }
