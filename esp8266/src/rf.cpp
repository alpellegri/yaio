#include <Arduino.h>
#include <RCSwitch.h>

#include <stdio.h>
#include <string.h>

RCSwitch mySwitch = RCSwitch();
uint32_t RadioCode;

uint32_t RadioCodes[10];
uint16_t RadioCodesLen = 0;

void RF_ResetRadioCodeDB(void) { RadioCodesLen = 0; }

void RF_AddRadioCodeDB(String string) {
  RadioCodes[RadioCodesLen++] = atoi(string.c_str());
}

bool RF_CheckRadioCodeDB(uint32_t code) {
  bool res = false;

  uint8_t i = 0;
  while ((i < RadioCodesLen) && (res == false)) {
    Serial.printf("> %x, %x\n", code, RadioCodes[i]);
    if (code == RadioCodes[i]) {
      res = true;
    }
    i++;
  }

  Serial.printf(">> %d\n", res);

  return res;
}

uint32_t RF_GetRadioCode(void) {
  uint32_t Code;

  Code = RadioCode;
  RadioCode = 0;

  return Code;
}

bool RF_Enable(void) {
  bool ret = true;

  RadioCode = 0;
  Serial.printf("RF Enable\n");
  mySwitch.enableReceive(D7); // gpio13 D7

  return ret;
}

bool RF_Disable(void) {
  bool ret = true;

  RadioCode = 0;
  Serial.printf("RF disable\n");
  mySwitch.disableReceive(); // gpio13 D7

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
      if (RadioCode == 0) {
        Serial.printf("radio code: %x\n", value);
        RadioCode = value;
      } else {
        Serial.printf(".\n", value);
      }
    }
  }
}

/* main function task */
bool RF_Task(void) {
  bool ret = true;

  return ret;
}
