#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include <Adafruit_Sensor.h>
#include <DHT.h>

#include "debug.h"
#include "fbutils.h"
#include "pht.h"

#define SAMPLE_PERIOD 60000

#define lpfilter(y, x) (0.95 * (y) + 0.05 * (x))

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

void PHT_Deinit(void) {
  pht_state = 0;
  delete dht;
}

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
        humidity = lpfilter(humidity, h);
        temperature = lpfilter(temperature, t);
        // DEBUG_PRINT("pht: %f, %f\n", humidity, temperature);

        bool wblog = false;
        if ((current_time - schedule_time) > pht_period) {
          schedule_time = current_time;
          wblog = true;
        }

        uint8_t len = FB_getIoEntryLen();
        uint16_t i = 0;
        while (i < len) {
          IoEntry &entry = FB_getIoEntry(i);
          if (entry.code == kDhtHumidity) {
            pht_humidity = 100 * (humidity + 0.05);
            entry.value = String(pht_humidity);
            entry.wb = true;
            entry.wblog = wblog;
          } else if (entry.code == kDhtTemperature) {
            pht_temperature = 100 * (temperature + 0.05);
            entry.value = String(pht_temperature);
            entry.wb = true;
            entry.wblog = wblog;
          } else {
          }
          i++;
        }
      }
    }
    break;
  }
}
