#!/bin/bash

file=../.pio/build/nodemcuv2/firmware.bin
cp $file ESP8266firmware.bin
printf $(md5sum ESP8266firmware.bin) > ESP8266firmware.md5