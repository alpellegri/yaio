#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include <Adafruit_Sensor.h>
#include <DHT.h>

#include "pht.h"
#include "debug.h"

#define DHTPIN D6
#define DHTTYPE DHT22

DHT *dht;
static uint8_t pht_state;
static uint8_t pht_pin;
static uint32_t pht_period;
static uint32_t schedule_time;
static uint32_t humidity_data;
static uint32_t temperature_data;

void PHT_Set(uint8_t pin, uint32_t period) {
  DEBUG_PRINT("DHT_Set %d, %d\n", pin, period);
  pht_pin = pin;
  pht_period = period * 60 * 1000;
  pht_state = 1;
}

uint32_t PHT_GetTemperature(void) { return temperature_data; }
uint32_t PHT_GetHumidity(void) { return humidity_data; }

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
    break;
  case 2:
    if ((current_time - schedule_time) > pht_period) {
      schedule_time = current_time;
      float h = dht->readHumidity() + 0.05;
      float t = dht->readTemperature() + 0.05;
      DEBUG_PRINT("pht_period %d, t: %f - h: %f\n", pht_period, t, h);
      if (isnan(h) || isnan(t)) {
      } else {
        humidity_data = 10 * h;
        temperature_data = 10 * t;
      }
    }
    break;
  }
}
