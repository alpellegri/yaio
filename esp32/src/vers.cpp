#define VERSION "0.1.0.2"

static const char *build_str = "HW:[esp32] - SW:[" VERSION "] | " __DATE__ " " __TIME__;

const char *VERS_getVersion(void) { return build_str; }
