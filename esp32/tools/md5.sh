#!/bin/bash

file=../.pioenvs/esp32dev/firmware.bin
cp $file .
printf $(md5sum $file) > firmware.md5