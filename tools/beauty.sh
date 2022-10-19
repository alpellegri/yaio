#!/bin/bash

root=../esp32/src
clang-format -i $root/*.cpp $root/*.h 

root=../esp8266/src
clang-format -i $root/*.cpp $root/*.h 
