/*
    Ticker
    Copyright (C) 2017  Pedro Albuquerque

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

//
// This lib mimics the Ticker library from ESP8266 package to make code
// compatible with ESP32 for this library to work properly it should be
// installed in ESP32 package folder
//  assuming ESP32 package has been installed a folder named
//  Projects/hardware/espressif/esp32 should exist
// and a subfolder named Ticker must be created there
// it will only be available when ESP32 board is selected, but unavailable for
// other boards
//
// This implementation of Ticker, makes use of timer 0 so any other need in your
// sketch should avoid timer 0 and use any other available timer

#ifndef TICKER_H
#define TICKER_H

#include <Arduino.h>

class Ticker {
public:
  hw_timer_t *timer = NULL;

  void attach(unsigned milis, void func()) {
    // Use 1st timer of 4 (counted from zero).
    // Set 80 divider for prescaler (see ESP32 Technical Reference Manual for
    // more info).
    timer = timerBegin(0, 80, true);
    // Attach onTimer function to our timer.
    timerAttachInterrupt(timer, func, true);
    // Set alarm to call onTimer function every second (value in microseconds).
    // Repeat the alarm (third parameter)
    timerAlarmWrite(timer, milis, true);
    // Start an alarm
    timerAlarmEnable(timer);
  }

  void ICACHE_RAM_ATTR detach() {
    timerDetachInterrupt(timer);
    timer = NULL;
  }
};

#endif
