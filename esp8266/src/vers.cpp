#define STRINGIZER(arg) #arg
#define STR_VALUE(arg) STRINGIZER(arg)

#define VERSION STRINGIZER(1) "." STRINGIZER(4)
const char *build_str = VERSION " " __DATE__ " " __TIME__;

const char *VERS_getVersion(void) { return build_str; }
