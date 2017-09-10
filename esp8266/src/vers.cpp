#define STRINGIZER(arg) #arg
#define STR_VALUE(arg) STRINGIZER(arg)

#define MAJOR 1
#define MINOR 5

#define VERSION STRINGIZER(MAJOR) "." STRINGIZER(MINOR)
const char *build_str = VERSION " " __DATE__ " " __TIME__;

const char *VERS_getVersion(void) { return build_str; }
