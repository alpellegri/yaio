#include <Arduino.h>

#include <math.h>
#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "fbutils.h"
#include "pio.h"

#define SAMPLE_PERIOD (60 * 1000)

void PIO_Set(uint8_t code, uint32_t ioctl) {
  uint8_t pin = ioctl & 0xFF;
  switch (code) {
  case kPhyDIn:
  case kPhyAIn: {
    pinMode(pin, INPUT);
  } break;
  case kPhyDOut:
  case kPhyAOut: {
    pinMode(pin, OUTPUT);
  } break;
  default:
    break;
  }
}

void PIO_Service(void) {
  uint32_t current_time = millis();
  uint8_t len = FB_getIoEntryLen();
  uint16_t i = 0;
  while (i < len) {
    IoEntry &entry = FB_getIoEntry(i);
    switch (entry.code) {
    case kPhyDIn: {
      uint32_t v = atoi(entry.value.c_str());
      uint8_t pin = entry.ioctl;
      uint32_t period = (entry.ioctl >> 8) * SAMPLE_PERIOD;
      uint32_t value = digitalRead(pin);
      if (value != v) {
        entry.value = String(value);
        if ((current_time - entry.ev_tmstamp) > SAMPLE_PERIOD) {
          entry.ev_tmstamp = current_time;
          entry.wb = 1;
        }
      }
      if ((current_time - entry.ev_tmstamp_log) > period) {
        entry.ev_tmstamp_log = current_time;
        entry.wblog = 1;
      }
    } break;
    case kPhyAIn: {
      uint32_t v = atoi(entry.value.c_str());
      uint8_t pin = entry.ioctl;
      uint32_t period = (entry.ioctl >> 8) * SAMPLE_PERIOD;
      uint32_t value = analogRead(pin);
      // DEBUG_PRINT("pio: %d %d %d\n", current_time, entry.ev_tmstamp,
      //             current_time - entry.ev_tmstamp);
      if (value != v) {
        entry.value = String(value);
        if ((current_time - entry.ev_tmstamp) > SAMPLE_PERIOD) {
          entry.ev_tmstamp = current_time;
          // DEBUG_PRINT("pio: %d\n", entry.ev_tmstamp);
          entry.wb = 1;
        }
      }
      // DEBUG_PRINT("pio: %d %d\n", current_time - entry.ev_tmstamp_log,
      // period);
      if ((current_time - entry.ev_tmstamp_log) > period) {
        entry.ev_tmstamp_log = current_time;
        entry.wblog = 1;
      }
    } break;
    default:
      break;
    }
    i++;
  }
}
