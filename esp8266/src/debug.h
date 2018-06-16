#ifndef DEBUG_H
#define DEBUG_H

#define DEBUG_PRINT(fmt, ...) Serial.printf_P(PSTR(fmt), ##__VA_ARGS__)

#endif
