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
  mySwitch.enableTransmit(10); // gpio 10  sd3
  mySwitch.enableReceive(D7);  // gpio13 D7
  // mySwitch.setProtocol(1);
  // mySwitch.setPulseLength(420);   // orig338
  // mySwitch.setRepeatTransmit(15); // originale 15

  return ret;
}

void RF_Loop() {
  if (mySwitch.available()) {

    uint32_t value = (uint32_t)mySwitch.getReceivedValue();

    if (value == 0) {
      Serial.print("Unknown encoding");
    } else {
      // Serial.printf(">>%x\n", value);
      // Serial.print(" / ");
      // Serial.print(mySwitch.getReceivedBitlength());
      // Serial.print("bit ");
      // Serial.print("Protocol: ");
      // Serial.println(mySwitch.getReceivedProtocol());
      if (RadioCode == 0) {
        Serial.printf(">>%x\n", value);
        RadioCode = value;
      } else {
        Serial.printf(".", value);
      }
    }

    mySwitch.resetAvailable();
  }
}

/* main function task */
bool RF_Task(void) {
  bool ret = true;

  return ret;
}
