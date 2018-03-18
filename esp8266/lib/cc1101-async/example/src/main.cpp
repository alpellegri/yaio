#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include <RCSwitch.h>

#include "cc1101.h"

#define LEDOUTPUT 16

#define PORT_GDO0 5
#define PORT_GDO2 4


CC1101 cc1101;
RCSwitch mySwitch = RCSwitch();

void setup() {
  uint8_t data;
  Serial.begin(115200);

  cc1101.init();

  // setup the blinker output
  pinMode(LEDOUTPUT, OUTPUT);
  digitalWrite(LEDOUTPUT, LOW);

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

  mySwitch.enableTransmit(PORT_GDO0);
  mySwitch.setPolarity(true);
  mySwitch.enableReceive(PORT_GDO2);
  cc1101.strobe(CC1101_SIDLE);
  cc1101.strobe(CC1101_SRX);
}

uint32_t schedule_time;

void loop() {
  uint8_t data;
  uint16_t i;

  if (mySwitch.available()) {
    Serial.print("Received ");
    Serial.print(mySwitch.getReceivedValue());
    Serial.print(" / ");
    Serial.print(mySwitch.getReceivedBitlength());
    Serial.print("bit ");
    Serial.print("Protocol: ");
    Serial.println(mySwitch.getReceivedProtocol());

    mySwitch.resetAvailable();
  }

  uint32_t current_time = millis();
  if ((current_time - schedule_time) > 1000) {
    schedule_time = current_time;
    digitalWrite(LEDOUTPUT, LOW);

    // mySwitch.send("000000000001010100010001");

    digitalWrite(LEDOUTPUT, HIGH);
  }
}
