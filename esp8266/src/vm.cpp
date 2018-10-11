#include <Arduino.h>

#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "fbconf.h"
#include "fblog.h"
#include "fbm.h"
#include "fbutils.h"
#include "firebase.h"
#include "pht.h"
#include "rf.h"
#include "timers.h"
#include "timesrv.h"
#include "vmasm.h"

bool VM_UpdateDataPending;
void VM_UpdateDataReq(void) { VM_UpdateDataPending = true; }

void VM_readIn(void) {
  RF_Service();
  PHT_Service();
  Timers_Service();
  bool UpdateDataFault = false;

  /* loop over data elements looking for events */
  for (uint8_t id = 0; id < FB_getIoEntryLen(); id++) {
    IoEntry &entry = FB_getIoEntry(id);
    switch (entry.code) {
    case kPhyIn: {
      uint32_t v = atoi(entry.value.c_str());
      uint8_t pin = entry.ioctl;
      pinMode(pin, INPUT);
      uint32_t value = digitalRead(pin);
      if (v != value) {
        DEBUG_PRINT("VM_readIn: %s, %d, %d\n", entry.key.c_str(), value, v);
        entry.value = value;
        entry.ev = true;
        entry.ev_value = value;
        entry.wb = true;
        entry.wblog = true;
      }
    } break;
    case kPhyOut: {
      if ((VM_UpdateDataPending == true) && (entry.enWrite == true)) {
        DEBUG_PRINT("get: kPhyOut %s\n", entry.key.c_str());
        String kdata;
        FbSetPath_data(kdata);
        uint32_t value =
            Firebase.getInt(kdata + F("/") + entry.key + F("/value"));
        if (Firebase.failed() == true) {
          DEBUG_PRINT("get failed: kPhyOut %s\n", entry.key.c_str());
        } else {
          uint32_t v = atoi(entry.value.c_str());
          if (v != value) {
            DEBUG_PRINT("VM_readIn: %s, %d, %d\n", entry.key.c_str(), value, v);
            entry.value = value;
            entry.ev = true;
            entry.ev_value = value;
            entry.wb = true;
          }
        }
      }
    } break;
    case kBool: {
      if ((VM_UpdateDataPending == true) && (entry.enWrite == true)) {
        DEBUG_PRINT("get: kBool %s\n", entry.key.c_str());
        String kdata;
        FbSetPath_data(kdata);
        bool value = Firebase.getBool(kdata + F("/") + entry.key + F("/value"));
        if (Firebase.failed() == true) {
          DEBUG_PRINT("get failed: kBool %s\n", entry.key.c_str());
          UpdateDataFault = true;
        } else {
          uint32_t v = atoi(entry.value.c_str());
          if (v != value) {
            DEBUG_PRINT("VM_readIn: %s, %d\n", entry.key.c_str(), value);
            entry.value = value;
            entry.ev = true;
            entry.ev_value = value;
            entry.wblog = true;
          }
        }
      }
    } break;
    case kInt: {
      if ((VM_UpdateDataPending == true) && (entry.enWrite == true)) {
        DEBUG_PRINT("get: kInt %s\n", entry.key.c_str());
        String kdata;
        FbSetPath_data(kdata);
        uint32_t value =
            Firebase.getInt(kdata + F("/") + entry.key + F("/value"));
        if (Firebase.failed() == true) {
          DEBUG_PRINT("get failed: kInt %s\n", entry.key.c_str());
          UpdateDataFault = true;
        } else {
          uint32_t v = atoi(entry.value.c_str());
          if (v != value) {
            DEBUG_PRINT("VM_readIn: %s, %d\n", entry.key.c_str(), value);
            entry.value = value;
            entry.ev = true;
            entry.ev_value = value;
            entry.wblog = true;
          }
        }
      }
    } break;
    default:
      // DEBUG_PRINT("VM_readIn: error\n");
      break;
    }
  }
  VM_UpdateDataPending = UpdateDataFault;
}

void VM_writeOutMessage(vm_context_t &ctx, String value) {
  DEBUG_PRINT("VM_writeOutMessage: %s\n", value.c_str());
  String message = value + F(" ") + ctx.ev_name;
  fblog_log(message, true);
}

void VM_writeOut(void) {
  uint32_t current = getTime();

  /* loop over data elements looking for write-back requests */
  for (uint8_t i = 0; i < FB_getIoEntryLen(); i++) {
    IoEntry &entry = FB_getIoEntry(i);
    if (entry.wb == true) {
      /* set event timestamp */
      entry.ev_tmstamp = current;
      switch (entry.code) {
      case kPhyOut: {
        uint32_t v = atoi(entry.value.c_str());
        uint8_t pin = entry.ioctl;
        pinMode(pin, OUTPUT);
        digitalWrite(pin, v);
        if (entry.enRead == true) {
          DEBUG_PRINT("VM_writeOut: %s: %d\n", entry.key.c_str(), v);
          String ref;
          FbSetPath_data(ref);
          Firebase.setInt(ref + F("/") + entry.key + F("/value"), v);
          if (Firebase.failed() == true) {
            DEBUG_PRINT("Firebase set failed: VM_writeOut %s\n",
                        entry.key.c_str());
          } else {
            entry.wb = false;
          }
        } else {
          entry.wb = false;
        }
      } break;
      case kRadioTx: {
        uint32_t v = atoi(entry.value.c_str());
        RF_Send(v, 24);
        entry.wb = false;
      } break;
      case kPhyIn:
      case kRadioIn:
      case kRadioRx:
      case kInt: {
        if (entry.enRead == true) {
          uint32_t v = atoi(entry.value.c_str());
          DEBUG_PRINT("VM_writeOut: %s: %d\n", entry.key.c_str(), v);
          String ref;
          FbSetPath_data(ref);
          Firebase.setInt(ref + F("/") + entry.key + F("/value"), v);
          if (Firebase.failed() == true) {
            DEBUG_PRINT("Firebase set failed: VM_writeOut %s\n",
                        entry.key.c_str());
          } else {
            if ((entry.enLog == true) && (entry.wblog == true)) {
              DynamicJsonBuffer jsonBuffer;
              JsonObject &json = jsonBuffer.createObject();
              json[F("t")] = getTime();
              json[F("v")] = v;
              String strdata;
              json.printTo(strdata);
              FbSetPath_log(ref);
              DEBUG_PRINT("VM_writeOut-log: %s: %d\n", entry.key.c_str(), v);
              Firebase.pushJSON(ref + F("/") + entry.key, strdata);
              if (Firebase.failed() == true) {
                DEBUG_PRINT("Firebase push failed: VM_writeOut %s\n",
                            entry.key.c_str());
              } else {
                entry.wb = false;
                entry.wblog = false;
              }
            } else {
              entry.wb = false;
            }
          }
        }
      } break;
      case kDhtTemperature:
      case kDhtHumidity:
      case kFloat: {
        if (entry.enRead == true) {
          float v = atof(entry.value.c_str());
          DEBUG_PRINT("VM_writeOut: %s: %f\n", entry.key.c_str(), v);
          String ref;
          FbSetPath_data(ref);
          Firebase.setFloat(ref + F("/") + entry.key + F("/value"), v);
          if (Firebase.failed() == true) {
            DEBUG_PRINT("Firebase set failed: VM_writeOut %s\n",
                        entry.key.c_str());
          } else {
            if ((entry.enLog == true) && (entry.wblog == true)) {
              DynamicJsonBuffer jsonBuffer;
              JsonObject &json = jsonBuffer.createObject();
              json[F("t")] = getTime();
              json[F("v")] = v;
              String strdata;
              json.printTo(strdata);
              FbSetPath_log(ref);
              DEBUG_PRINT("VM_writeOut-log: %s: %f\n", entry.key.c_str(), v);
              Firebase.pushJSON(ref + F("/") + entry.key, strdata);
              if (Firebase.failed() == true) {
                DEBUG_PRINT("Firebase push failed: VM_writeOut %s\n",
                            entry.key.c_str());
              } else {
                entry.wb = false;
                entry.wblog = false;
              }
            } else {
              entry.wb = false;
            }
          }
        }
      } break;
      case kBool: {
        if (entry.enRead == true) {
          bool v = atoi(entry.value.c_str());
          DEBUG_PRINT("VM_writeOut: %s: %d\n", entry.key.c_str(), v);
          String ref;
          FbSetPath_data(ref);
          Firebase.setBool(ref + F("/") + entry.key + F("/value"), v);
          if (Firebase.failed() == true) {
            DEBUG_PRINT("Firebase set failed: VM_writeOut %s\n",
                        entry.key.c_str());
          } else {
            entry.wb = false;
          }
        } else {
          entry.wb = false;
        }
      } break;
      case kTimer:
      case kTimeout: {
        DEBUG_PRINT("VM_writeOut: kTimer/kTimeout %s\n", entry.value.c_str());
        entry.wb = false;
      } break;
      case kMessaging: {
        DEBUG_PRINT("VM_writeOut: kMessaging %s\n", entry.value.c_str());
        fblog_log(entry.value, true);
        entry.wb = false;
      } break;
      default:
        // DEBUG_PRINT("VM_writeOut: error\n");
        break;
      }
    }
  }
}

void VM_run(void) {
  // update inputs
  VM_readIn();

  /* loop over data elements looking for event notifications */
  for (uint8_t i = 0; i < FB_getIoEntryLen(); i++) {
    IoEntry &entry = FB_getIoEntry(i);

    if (entry.ev == true) {
      entry.ev = false;
      String cbkey = entry.cb;

      DEBUG_PRINT("event found on: %s\n", entry.key.c_str());

      // DEBUG_PRINT("cbkey: %s\n", cbkey.c_str());
      if (cbkey.length() != 0) {
        vm_context_t ctx;

        /* init ACC with event value */
        ctx.V = 0;
        ctx.ACC = entry.ev_value;
        ctx.HALT = false;

        /* keep the event name */
        ctx.ev_name = entry.key.c_str();

        uint8_t id_prog = FB_getProgIdx(cbkey.c_str());
        ProgEntry &prog = FB_getProg(id_prog);
        std::vector<FuncEntry> &funcvec = prog.funcvec;

        DEBUG_PRINT("VM_run start [%s] >>>>>>>>>>>>\n", prog.key.c_str());
        DEBUG_PRINT("Heap: %d\n", ESP.getFreeHeap());

        uint8_t pc = 0;
        while ((pc < funcvec.size()) && (ctx.HALT == false)) {
          DEBUG_PRINT("VM_run start [%d] code=%d, ACC=%d V=%d\n", pc,
                      funcvec[pc].code, ctx.ACC, ctx.V);

          /* decode */
          pc = VM_decode(pc, ctx, funcvec[pc]);

          DEBUG_PRINT("VM_run stop [%d] code=%d, ACC=%d V=%d\n", pc,
                      funcvec[pc].code, ctx.ACC, ctx.V);
        }
        DEBUG_PRINT("VM_run stop [%s] <<<<<<<<<<<<\n", prog.key.c_str());
      }
    }
  }

  // update outputs
  VM_writeOut();
}
