#include <Arduino.h>
#include <RCSwitch.h>

#include <stdio.h>
#include <string.h>

RCSwitch mySwitch = RCSwitch();
uint32_t RadioCode;

uint32_t RF_GetRadioCode(void) {
  uint32_t Code;

  Code = RadioCode;
  RadioCode = 0;

  return Code;
}

bool RF_Setup(void) {
  bool ret = true;

  RadioCode = 0;
  Serial.printf("RF_Setup\n");
  mySwitch.enableReceive(D7); // gpio13 D7

  return ret;
}

void RF_Loop() {
  if (mySwitch.available()) {

    uint32_t value = (uint32_t)mySwitch.getReceivedValue();
    mySwitch.resetAvailable();

    if (value == 0) {
      Serial.print("Unknown encoding");
    } else {
      // Serial.printf(">>%x\n", value);
      // Serial.print(" / ");
      // Serial.print(mySwitch.getReceivedBitlength());
      // Serial.print("bit ");
      // Serial.print("Protocol: ");
      // Serial.println(mySwitch.getReceivedProtocol());
      Serial.printf(">>%x\n", value);
      if (RadioCode == 0) {
        RadioCode = value;
      }
    }
  }
}

/* main function task */
bool RF_Task(void) {
  bool ret = true;

  return ret;
}
