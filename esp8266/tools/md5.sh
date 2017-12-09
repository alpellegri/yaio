#!/bin/bash

file=../.pioenvs/nodemcuv2/firmware.bin
cp $file .
printf $(md5sum $file) > firmware.md5