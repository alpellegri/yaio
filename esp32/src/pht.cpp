#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include <Adafruit_Sensor.h>
#include <DHT.h>

#include "debug.h"
#include "fbutils.h"
#include "pht.h"

#define SAMPLE_PERIOD 5000
// #define DHTPIN D6 // 12
#define DHTTYPE DHT22

static DHT *dht;
static uint8_t pht_state;
static bool pht_init;
static uint8_t pht_pin;
static uint32_t pht_period;
static uint32_t sample_time;
static uint32_t schedule_time;
static uint16_t pht_humidity;
static uint16_t pht_temperature;
static float humidity;
static float temperature;

void PHT_Set(uint8_t pin, uint32_t period) {
  pht_pin = pin;
  pht_period = period * 60 * 1000;
  pht_state = 1;
  DEBUG_PRINT("PHT_Set %d, %d, %d\n", pin, period, pht_period);
}

/* main function task */
void PHT_Service(void) {
  // DEBUG_PRINT("pht_state: %d\n", pht_state);
  uint32_t current_time = millis();
  switch (pht_state) {
  case 0:
    break;
  case 1:
    dht = new DHT(pht_pin, DHTTYPE);
    dht->begin();
    pht_state = 2;
    pht_init = false;
    schedule_time = current_time;
    break;
  case 2: {
    float h = dht->readHumidity();
    float t = dht->readTemperature();
    if (isnan(h) || isnan(t)) {
      DEBUG_PRINT("dht sensor error\n");
    } else {
      pht_state = 3;
      pht_init = true;
      humidity = h;
      temperature = t;
    }
  } break;
  case 3:
    if ((current_time - sample_time) > SAMPLE_PERIOD) {
      sample_time = current_time;
      float h = dht->readHumidity();
      float t = dht->readTemperature();
      if (isnan(h) || isnan(t)) {
        DEBUG_PRINT("dht sensor error\n");
      } else {
        humidity = 0.9 * humidity + 0.1 * h;
        temperature = 0.9 * temperature + 0.1 * t;
        // DEBUG_PRINT("pht: %f, %f\n", humidity, temperature);

        uint8_t len = FB_getIoEntryLen();
        uint16_t i = 0;
        while (i < len) {
          IoEntry &entry = FB_getIoEntry(i);
          // uint32_t v = entry.ioctl;
          if (entry.code == kDhtHumidity) {
            pht_humidity = 10 * (humidity + 0.05);
            entry.value = String(pht_humidity);
            entry.wb = true;
          }
          if (entry.code == kDhtTemperature) {
            pht_temperature = 10 * (temperature + 0.05);
            entry.value = String(pht_temperature);
            entry.wb = true;
          }
          i++;
        }
      }
    }

    if ((current_time - schedule_time) > pht_period) {
      schedule_time = current_time;
      DEBUG_PRINT("pht event: %f, %f\n", humidity, temperature);

      uint8_t len = FB_getIoEntryLen();
      uint16_t i = 0;
      while (i < len) {
        IoEntry &entry = FB_getIoEntry(i);
        // uint32_t v = entry.ioctl;
        if (entry.code == kDhtHumidity) {
          pht_humidity = 10 * (humidity + 0.05);
          entry.value = String(pht_humidity);
          entry.ev = true;
          entry.wb = true;
        }
        if (entry.code == kDhtTemperature) {
          pht_temperature = 10 * (temperature + 0.05);
          entry.value = String(pht_temperature);
          entry.ev = true;
          entry.wb = true;
        }
        i++;
      }
    }
    break;
  }
}
