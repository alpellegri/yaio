#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include "ap.h"
#include "debug.h"
#include "ee.h"
#include "sta.h"
#include "vers.h"

#define LED D0    // Led in NodeMCU at pin GPIO16 (D0).
#define BUTTON D3 // flash button at pin GPIO00 (D3)

static uint8_t mode;
static uint32_t schedule_time;

void setup() {
  bool ret;

  pinMode(LED, OUTPUT);
  pinMode(BUTTON, INPUT);
  Serial.begin(115200);

  EE_Setup();

  DEBUG_PRINT("\nSW version: %s\n", VERS_getVersion().c_str());
  DEBUG_PRINT("Heap: %d\n", ESP.getFreeHeap());

  mode = 0;
  if (mode == 0) {
    ret = AP_Setup();
  } else if (mode == 1) {
    ret = STA_Setup();
    if (ret == false) {
      mode = 0;
      AP_Setup();
    }
  } else {
  }
}

void loop() {
  bool ret;

  if (mode == 0) {
    AP_Loop();
  } else if (mode == 1) {
    STA_Loop();
  } else {
  }

  uint32_t current_time = millis();
  if ((current_time - schedule_time) > 50) {
    schedule_time = current_time;
    if (mode == 0) {
      ret = AP_Task();
      if (ret == false) {
        /* try to setup STA */
        mode = STA_Setup();
      }
    } else if (mode == 1) {
      ret = STA_Task(current_time);
      if (ret == false) {
        STA_Setup();
      }
    } else {
      /* unmapped mode */
    }
  }
}
