#include <Arduino.h>
#include <RCSwitch.h>

#include <stdio.h>
#include <string.h>

RCSwitch mySwitch = RCSwitch();
uint32_t RadioCode;
bool RF_StatusEnable = false;

uint32_t RadioCodes[10];
uint16_t RadioCodesLen = 0;
uint32_t RadioCodesTx[10];
uint16_t RadioCodesTxLen = 0;

void RF_ResetRadioCodeDB(void) { RadioCodesLen = 0; }

void RF_ResetRadioCodeTxDB(void) { RadioCodesTxLen = 0; }

void RF_AddRadioCodeDB(String string) {
  Serial.printf("RF_AddRadioCodeDB: %s\n", string.c_str());
  RadioCodes[RadioCodesLen++] = atoi(string.c_str());
}

void RF_AddRadioCodeTxDB(String string) {
  Serial.printf("RF_AddRadioCodeTxDB: %s\n", string.c_str());
  RadioCodesTx[RadioCodesTxLen++] = atoi(string.c_str());
}

bool RF_CheckRadioCodeDB(uint32_t code) {
  bool res = false;

  uint8_t i = 0;
  Serial.printf("RF_CheckRadioCodeDB: code %x\n", code);
  while ((i < RadioCodesLen) && (res == false)) {
    Serial.printf("radio table: %x, %x\n", code, RadioCodes[i]);
    if (code == RadioCodes[i]) {
      Serial.printf("radio code found in table\n");
      res = true;
    }
    i++;
  }

  return res;
}

uint32_t RF_GetRadioCode(void) {
  uint32_t Code;

  Code = RadioCode;
  RadioCode = 0;

  return Code;
}

void RF_Enable(void) {
  if (RF_StatusEnable == false) {
    RF_StatusEnable = true;
    RadioCode = 0;
    Serial.printf("RF Enable\n");
    mySwitch.enableReceive(D7); // gpio13 D7
  }
}

void RF_Disable(void) {
  if (RF_StatusEnable == true) {
    RF_StatusEnable = false;
    RadioCode = 0;
    Serial.printf("RF disable\n");
    mySwitch.disableReceive(); // gpio13 D7
  }
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
