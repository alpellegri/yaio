#include "vers.h"

static const char *build_str =
    "HW:[" VERS_HW_VER "] - SW:[" VERS_SW_VER "] | " __DATE__ " " __TIME__;

const char *VERS_getVersion(void) { return build_str; }
