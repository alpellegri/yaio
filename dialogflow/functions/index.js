/**
* Copyright 2017 Google Inc. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
'use strict';

process.env.DEBUG = 'actions-on-google:*';

const DialogflowApp = require('actions-on-google').DialogflowApp;
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

const controlRef = admin.database().ref('/control');
const statusRef = admin.database().ref('/status');

// API.AI Intent names
const SET_RESOURCE_INTENT = 'setResource';
const GET_RESOURCE_INTENT = 'getResource';

const REQUEST_PERMISSION_ACTION = 'request_permission';
const GET_RIDE_ACTION = 'get_ride';
const WELCOME_INTENT = 'input.welcome';
const SIGN_IN = 'sign.in';

// Contexts
const RESOURCE_CONTEXT = 'resource';

// Context Parameters
const VALUE_PARAM = 'digital_value';
const RESOURCE_PARAM = 'resource';

exports.dialogflowFirebaseFulfillment = functions.https.onRequest((request, response) => {
  console.log('headers: ' + JSON.stringify(request.headers));
  console.log('body: ' + JSON.stringify(request.body));

  const app = new DialogflowApp({request: request, response: response});

  let actionMap = new Map();
  actionMap.set(SET_RESOURCE_INTENT, setResource);
  actionMap.set(GET_RESOURCE_INTENT, getResource);
  actionMap.set(REQUEST_PERMISSION_ACTION, requestPermission);
  actionMap.set(GET_RIDE_ACTION, sendRide);
  // actionMap.set(WELCOME_INTENT, welcomeIntent);
  actionMap.set(SIGN_IN, signIn);
  app.handleRequest(actionMap);

  function welcomeIntent (app) {
    app.askForSignIn();
  }

  function signIn(app) {
    if (app.getSignInStatus() === app.SignInStatus.OK) {
      let accessToken = app.getUser().accessToken;
      app.ask('Great, thanks for signing in!');
    } else {
      app.ask('I won\'t be able to save your data, but let\'s continue!');
    }
  }

  function requestPermission(app) {
    const permission = [
      app.SupportedPermissions.NAME,
      app.SupportedPermissions.DEVICE_PRECISE_LOCATION
    ];
    app.askForPermissions('To pick you up', permissions);
  }

  function sendRide(app) {
    if (app.isPermissionGranted()) {
      const displayName = app.getUserName().displayName;
      const address = app.getDeviceLocation().address;
      app.tell('I will tell your driver to pick up ' + displayName +
          ' at ' + address);
    } else {
      // Response shows that user did not grant permission
      app.tell('Sorry, I could not figure out where to pick you up.');
    }
  }

  function setResource(app) {
	// app.askForSignIn();
    let userId = app.getUser().userId;
    console.log(userId);
    const resource = app.getContextArgument(RESOURCE_CONTEXT, RESOURCE_PARAM).value;
    const value = app.getContextArgument(RESOURCE_CONTEXT, VALUE_PARAM).value;
    console.log('setResource');
    console.log(resource);
    console.log(value);
    var speech;
    if (resource === 'alarm') {
      if (value === 'off') {
        speech = `ok I will set ${resource} ${value}`;
        let current_date = new Date();
        controlRef.child('time').set(Math.floor(current_date.getTime() / 1000));
        controlRef.child('alarm').set(false);
      } else if (value === 'on') {
        speech = `ok I will set ${resource} ${value}`;
        let current_date = new Date();
        controlRef.child('time').set(Math.floor(current_date.getTime() / 1000));
        controlRef.child('alarm').set(true);
      } else {
        speech = `sorry this action is not available`;
      }
    } else {
      speech = `sorry this action is not available`;
    }

    app.ask(speech);
  }

  function getResource(app) {
    const resource = app.getContextArgument(RESOURCE_CONTEXT, RESOURCE_PARAM).value;
    console.log('getResource');
    console.log(resource);

    const resource_ref = statusRef.child(resource);
    resource_ref.once('value', snap => {
      console.log(`snap.val.q: ${snap.val()}`);
      const speech = `ok ${resource} is ${snap.val()}`;
      app.ask(speech);
    });
   }
});
