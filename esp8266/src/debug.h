#ifndef DEBUG_H
#define DEBUG_H

#define DEBUG_ENABLE
#ifdef DEBUG_ENABLE
#define DEBUG_PRINT(fmt, args...) do { \
  Serial.printf_P(PSTR(fmt), ##args); \
} while(0)
#else
#define DEBUG_PRINT(fmt, args...)
#endif

#endif
