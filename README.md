# uHome

a **Cloud Home Automation** based on:
* Firbase + FCM
* ESP8266 / ESP32

Please note that this is in **Alpha status**. This project is **under heavy development, experimental, unversioned and not stable**.

## **Features**
* Cloud (Firebase)
* Hybrid Android app (Ionic)
* DTH22
* RF433
* SSD1306

## Install

### get uHome
```
https://github.com/alpellegri/uHome.git
```
### Firebase
create a Firebase account
### Ionic
First, install Node.js 6.x LTS.
```
npm install -g cordova ionic
cd ionic
ionic start . --no-overwriting
```
#### to start app on browser
```
ionic serve
```
#### to install app on device
```
ionic cordova run android
```
### ESP8266
Install platformio. Build esp8266 folder
