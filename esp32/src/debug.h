#ifndef DEBUG_H
#define DEBUG_H

#define DEBUG_ENABLE
#ifdef DEBUG_ENABLE
#define DEBUG_PRINT(fmt, ...) Serial.printf_P(PSTR(fmt), ##__VA_ARGS__)
#else
#define DEBUG_PRINT(fmt, ...)
#endif

#endif
