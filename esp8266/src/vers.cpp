#define VERSION "0.2.0.5"

static const char *build_str = "HW:[esp8266] - SW:[" VERSION "] | " __DATE__ " " __TIME__;

const char *VERS_getVersion(void) { return build_str; }
