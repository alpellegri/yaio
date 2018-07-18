#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include <Adafruit_Sensor.h>
#include <DHT.h>

#include "debug.h"
#include "pht.h"

#define DHTPIN D6 // 12
#define DHTTYPE DHT22

DHT *dht;
static uint8_t pht_state;
static bool pht_init;
static uint8_t pht_pin;
static uint16_t pht_period;
static uint32_t schedule_time;
static uint16_t humidity_data;
static uint16_t temperature_data;

void PHT_Set(uint8_t pin, uint32_t period) {
  DEBUG_PRINT("DHT_Set %d, %d\n", pin, period);
  pht_pin = pin;
  pht_period = period * 60 * 1000;
  pht_state = 1;
}

bool PHT_GetTemperature(uint16_t *t) {
  *t = temperature_data;
  return pht_init;
}
bool PHT_GetHumidity(uint16_t *h) {
  *h = humidity_data;
  return pht_init;
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
    break;
  case 2:
    if ((current_time - schedule_time) > pht_period) {
      schedule_time = current_time;
      float h = dht->readHumidity() + 0.05;
      float t = dht->readTemperature() + 0.05;
      DEBUG_PRINT("pht_period %d, t: %f - h: %f\n", pht_period, t, h);
      if (isnan(h) || isnan(t)) {
        DEBUG_PRINT("dht sensor error\n");
      } else {
        pht_init = true;
        humidity_data = 10 * h;
        temperature_data = 10 * t;
      }
    }
    break;
  }
}
