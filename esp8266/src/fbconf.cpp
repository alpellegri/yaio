#include <Arduino.h>
#include <FirebaseArduino.h>

#include <stdio.h>
#include <string.h>

#include "fbconf.h"
#include "fcm.h"
#include "rf.h"

bool FbmUpdateRadioCodes(void) {
  bool ret = true;
  yield();

  if (ret == true) {
    FirebaseObject ref = Firebase.get(F("FCM_Registration_IDs"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: FCM_Registration_IDs"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      FcmResetRegIDsDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject &nestedObject = i->value;
        String id = i->value.asString();
        Serial.println(id);
        FcmAddRegIDsDB(id);
      }
    }
  }

  if (ret == true) {
    Serial.println(F("FbmUpdateRadioCodes Rx"));
    FirebaseObject ref = Firebase.get(F("RadioCodes/Active"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: RadioCodes/Active"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_DeInitRadioCodeDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }
      RF_InitRadioCodeDB(num);
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject &nestedObject = i->value;
        String id = nestedObject["id"];
        String name = nestedObject["name"];
        String func = nestedObject["func"];
        Serial.println(id);
        RF_AddRadioCodeDB(id, name, func);
      }
    }
  }

  if (ret == true) {
    Serial.println(F("FbmUpdateRadioCodes Tx"));
    FirebaseObject ref = Firebase.get(F("RadioCodes/ActiveTx"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: RadioCodes/ActiveTx"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_DeInitRadioCodeTxDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }
      RF_InitRadioCodeTxDB(num);
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject &nestedObject = i->value;
        String id = nestedObject["id"];
        Serial.println(id);
        RF_AddRadioCodeTxDB(id);
      }
    }
  }

  if (ret == true) {
    Serial.println(F("FbmUpdateRadioCodes Timers"));
    FirebaseObject ref = Firebase.get(F("Timers"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: Timers"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_DeInitTimerDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }
      RF_InitTimerDB(num);
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject &nestedObject = i->value;
        String type = nestedObject["type"];
        String action = nestedObject["action"];
        String hour = nestedObject["hour"];
        String minute = nestedObject["minute"];
        Serial.println(action);
        RF_AddTimerDB(type, action, hour, minute);
      }
    }
  }

  if (ret == true) {
    Serial.println(F("FbmUpdateDIO Dout"));
    FirebaseObject ref = Firebase.get(F("DIO/Dout"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: DIO/Dout"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_DeInitDoutDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }
      RF_InitDoutDB(num);
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject &nestedObject = i->value;
        String id = nestedObject["id"];
        Serial.println(id);
        RF_AddDoutDB(id);
      }
    }
  }

  if (ret == true) {
    Serial.println(F("FbmUpdateLIO Lout"));
    FirebaseObject ref = Firebase.get(F("LIO/Lout"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: LIO/Lout"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_DeInitLoutDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }
      RF_InitLoutDB(num);
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject &nestedObject = i->value;
        String id = nestedObject["id"];
        Serial.println(id);
        RF_AddLoutDB(id);
      }
    }
  }

  if (ret == true) {
    Serial.println(F("FbmUpdateFuncions"));
    FirebaseObject ref = Firebase.get(F("Functions"));
    if (Firebase.failed() == true) {
      Serial.print(F("get failed: Funcions"));
      Serial.println(Firebase.error());
      ret = false;
    } else {
      RF_DeInitFunctionsDB();
      JsonVariant variant = ref.getJsonVariant();
      JsonObject &object = variant.as<JsonObject>();
      uint8_t num = 0;
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        num++;
      }
      RF_InitFunctionsDB(num);
      for (JsonObject::iterator i = object.begin(); i != object.end(); ++i) {
        yield();
        // Serial.println(i->key);
        JsonObject &nestedObject = i->value;
        String name = nestedObject["name"];
        String type = nestedObject["type"];
        String action = nestedObject["action"];
        String delay = nestedObject["delay"];
        String next = nestedObject["next"];
        Serial.println(name);
        RF_AddFunctionsDB(name, type, action, delay, next);
      }
    }
  }

  return ret;
}
