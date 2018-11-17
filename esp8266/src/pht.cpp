#include <Arduino.h>

#include <math.h>
#include <stdio.h>
#include <string.h>

#include <Adafruit_Sensor.h>
#include <DHTesp.h>

#include "debug.h"
#include "fbutils.h"
#include "pht.h"

#define SAMPLE_PERIOD_DHT (2 * 1000)
#define SAMPLE_PERIOD (60 * 1000)

#define lpfilter(y, x) (0.95 * (y) + 0.05 * (x))
#define round2d(x) (roundf((x)*100) / 100)

// #define DHTPIN D6 // 12
#define DHTTYPE DHTesp ::DHT22

static DHTesp *dht;
static uint8_t pht_state;
static bool pht_init;
static uint8_t pht_pin;
static uint32_t pht_period;
static uint32_t sample_time;
static uint32_t schedule_time;
static float humidity;
static float temperature;

void PHT_Deinit(void) {
  pht_state = 0;
  delete dht;
}

void PHT_Set(uint32_t ioctl) {
  uint8_t pin = ioctl & 0xFF;
  uint32_t period = ioctl >> 8;
  pht_pin = pin;
  pht_period = period * SAMPLE_PERIOD;
  pht_state = 1;
  DEBUG_PRINT("PHT_Set %d, %d, %d\n", pin, period, pht_period);
}

void PHT_Service(void) {
  uint32_t current_time = millis();
  // DEBUG_PRINT("pht_state: %d %d %e %e\n", pht_state, current_time -
  // sample_time,
  //             humidity, temperature);
  switch (pht_state) {
  case 0:
    break;
  case 1:
    sample_time = current_time;
    dht = new DHTesp();
    dht->setup(pht_pin, DHTTYPE);
    pht_state = 2;
    pht_init = false;
    break;
  case 2: {
    if ((current_time - sample_time) > SAMPLE_PERIOD_DHT) {
      sample_time = current_time;
      float h = dht->getHumidity();
      float t = dht->getTemperature();
      if (isnan(h) || isnan(t)) {
        DEBUG_PRINT("dht sensor error\n");
      } else {
        pht_state = 3;
        pht_init = true;
        humidity = h;
        temperature = t;
        schedule_time = current_time;
        DEBUG_PRINT("pht: %f, %f\n", humidity, temperature);
      }
    }
  } break;
  case 3:
    if ((current_time - sample_time) > SAMPLE_PERIOD) {
      sample_time = current_time;
      float h = dht->getHumidity();
      float t = dht->getTemperature();
      if (isnan(h) || isnan(t)) {
        DEBUG_PRINT("dht sensor error\n");
      } else {
        humidity = lpfilter(humidity, h);
        temperature = lpfilter(temperature, t);
        DEBUG_PRINT("pht: %f, %f\n", humidity, temperature);

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
            entry.value = String(round2d(humidity));
            entry.wb = 1;
            entry.wblog = wblog;
          } else if (entry.code == kDhtTemperature) {
            entry.value = String(round2d(temperature));
            entry.wb = 1;
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
