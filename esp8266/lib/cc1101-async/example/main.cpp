#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include "cc1101.h"

#define LEDOUTPUT 13

#define PORT_GDO0 14
#define PORT_GDO2 15

CC1101 cc1101;

void setup() {
  uint8_t data;
  Serial.begin(115200);

  cc1101.setSoftCS(4);
  cc1101.begin();

  // setup the blinker output
  pinMode(LEDOUTPUT, OUTPUT);
  // digitalWrite(LEDOUTPUT, LOW);


  Serial.println("");
  Serial.print("CC1101_VERSION ");
  data = cc1101.readStatus(CC1101_VERSION);
  Serial.println(data);
  Serial.print("CC1101_PKTCTRL0 ");
  data = cc1101.readReg(CC1101_PKTCTRL0);
  Serial.println(data);
  Serial.print("CC1101_MDMCFG2 ");
  data = cc1101.readReg(CC1101_MDMCFG2);
  Serial.println(data);

  cc1101.enableTransmit(PORT_GDO0);
  cc1101.enableReceive(PORT_GDO2);
}

uint32_t schedule_time;

void loop() {
  uint8_t data;
  uint16_t i;

  if (cc1101.available()) {
    Serial.print("Received ");
    Serial.print(cc1101.getReceivedValue());
    Serial.print(" / ");
    Serial.print(cc1101.getReceivedBitlength());
    Serial.print("bit ");
    Serial.print("Protocol: ");
    Serial.println(cc1101.getReceivedProtocol());

    cc1101.resetAvailable();
  }

  uint32_t current_time = millis();
  if ((current_time - schedule_time) > 3000) {
    schedule_time = current_time;
    digitalWrite(LEDOUTPUT, LOW);

    // cc1101.send(0x55555555, 32);

    digitalWrite(LEDOUTPUT, HIGH);
  }
}
