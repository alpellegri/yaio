#include <Arduino.h>
#include <Ticker.h>

#include <SPI.h>
#include <Wire.h>
// #include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#include <stdio.h>
#include <string.h>

#include "ap.h"
#include "ee.h"
#include "rf.h"
#include "sta.h"

#define LED D0    // Led in NodeMCU at pin GPIO16 (D0).
#define BUTTON D3 // flash button at pin GPIO00 (D3)

#define OLED_RESET LED_BUILTIN // 4

// Adafruit_SSD1306 display(OLED_RESET);

uint8_t mode;
uint16_t count = 0;
uint32_t current_time;
uint32_t schedule_time;

void setup() {
  bool ret;

  pinMode(LED, OUTPUT);
  pinMode(BUTTON, INPUT);
  Serial.begin(115200);

  EE_Setup();

  Serial.println();
  Serial.println("Node starting...");

#if 0
  // init oled display
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  // Clear the buffer.
  display.clearDisplay();
  display.display();

  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0, 0);
  display.println("WIFI mode");
  display.setTextSize(2);
  display.println("AP");
  display.display();
#endif

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

  RF_Loop();

  if (mode == 0) {
    AP_Loop();
  } else if (mode == 1) {
    STA_Loop();
  } else {
  }

  current_time = millis();
  if ((current_time - schedule_time) > 500) {
    schedule_time = current_time;
    if (mode == 0) {
      ret = AP_Task();
      if (ret == false) {
        /* try to setup STA */
        mode = STA_Setup();
      }
    } else if (mode == 1) {
      ret = STA_Task();
      if (ret == false) {
        mode = 0;
        AP_Setup();
      }
    } else {
      /* unmapped mode */
    }
  }
}
