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

const util = require('util');
const https = require('https');
const functions = require('firebase-functions');
const firebase = require('firebase');
// Initialize Firebase
const config = functions.config().firebase;
var admin = require("firebase-admin");
var serviceAccount = require("./smarthome-washer-firebase-adminsdk-knmtl-c749309e3b.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://smarthome-washer.firebaseio.com"
});

exports.login = functions.https.onRequest((request, response) => {
  console.log('-> Request headers: ' + JSON.stringify(request.headers));
  console.log('-> Request query: ' + JSON.stringify(request.query));
  console.log('-> Request body: ' + JSON.stringify(request.body));

  if (!request.headers.authorization || !request.headers.authorization.startsWith('Bearer ')) {
    console.error('No Firebase ID token was passed as a Bearer token in the Authorization header.');
    response.status(403).send('Unauthorized');
    return;
  }

  let idToken;
  if (request.headers.authorization && request.headers.authorization.startsWith('Bearer ')) {
    console.log('Found "Authorization" header');
    // Read the ID Token from the Authorization header.
    idToken = request.headers.authorization.split('Bearer ')[1];
  } else {
    // No cookie
    response.status(403).send('Unauthorized');
    return;
  }
  admin.auth().verifyIdToken(idToken).then((decodedIdToken) => {
    console.log('ID Token correctly decoded', decodedIdToken);
	  response.send(decodedIdToken.uid);
  }).catch((error) => {
    console.error('Error while verifying Firebase ID token:', error);
    response.status(403).send('Unauthorized');
  });
});

exports.auth = functions.https.onRequest((request, response) => {
  console.log('-> Request headers: ' + JSON.stringify(request.headers));
  console.log('-> Request query: ' + JSON.stringify(request.query));
  console.log('-> Request body: ' + JSON.stringify(request.body));

	// const responseurl = util.format('%s?code=%s&state=%s',
  //   decodeURIComponent(request.query.redirect_uri), 'xxxxxx', request.query.state);
	const responseurl = util.format('%s?code=%s&state=%s',
    decodeURIComponent(request.query.redirect_uri), request.query.code, request.query.state);
  console.log('-> request.query.code: ' + request.query.code);
  console.log('-> responseurl: ' + responseurl);
  return response.redirect(responseurl);
});

exports.token = functions.https.onRequest((request, response) => {
  console.log('-> Request headers: ' + JSON.stringify(request.headers));
  console.log('-> Request query: ' + JSON.stringify(request.query));
  console.log('-> Request body: ' + JSON.stringify(request.body));
  const grantType = request.query.grant_type
    ? request.query.grant_type : request.body.grant_type;
  const expires = 1 * 1 * 60;
  const HTTP_STATUS_OK = 200;
  console.log(`Grant type ${grantType}`);

  let obj;
  if (grantType === 'authorization_code') {
    obj = {
      token_type: 'bearer',
      access_token: 'pinco',
      refresh_token: 'pallo',
      expires_in: expires,
    };
  } else if (grantType === 'refresh_token') {
    obj = {
      token_type: 'bearer',
      access_token: 'pinco',
      expires_in: expires,
    };
  }
  response.status(HTTP_STATUS_OK)
    .json(obj);
});

exports.ha = functions.https.onRequest((req, res) => {
  console.log('-> Request headers: ' + JSON.stringify(req.headers));
  console.log('-> Request query: ' + JSON.stringify(req.query));
  console.log('-> Request body: ' + JSON.stringify(req.body));

  let authToken = req.headers.authorization ? req.headers.authorization.split(' ')[1] : null;
  console.log('authToken: ' + authToken);
  init(req, res);
});

function init(req, res) {
  let reqdata = req.body;

  if (!reqdata.inputs) { showError(res, "missing inputs"); return; }

  for (let i = 0; i < reqdata.inputs.length; i++) {
    let input = reqdata.inputs[i];
		let intent = input.intent || "";
		console.log('> intent ', intent);
    switch (intent) {
      case "action.devices.SYNC":
        sync(reqdata, res);
        return;
      case "action.devices.QUERY":
        query(reqdata, res);
        return;
      case "action.devices.EXECUTE":
        execute(reqdata, res);
        return;
    }
  }
  showError(res, "missing intent");
}

function sync(reqdata, res) {
  let deviceProps = {
    requestId: reqdata.requestId,
    payload: {
      devices: [{
        id: "1",
        type: "action.devices.types.SWITCH",
        traits: [
          "action.devices.traits.OnOff"
        ],
        name: {
          name: "fan"
        },
        willReportState: true
      }, {
        id: "2",
        type: "action.devices.types.LIGHT",
        traits: [
          "action.devices.traits.OnOff",
          "action.devices.traits.ColorSpectrum"
        ],
        name: {
          name: "lights"
        },
        willReportState: true
      }]
    }
  };
  res.status(200).json(deviceProps);
}

function query(reqdata, res) {
  getDevicesDataFromFirebase(devices => {
    let deviceStates = {
      requestId: reqdata.requestId,
      payload: {
        devices: {
          "1": {
            on: devices.fan.on,
            online: true
          },
          "2": {
            on: devices.lights.on,
            online: true,
            color: {
              spectrumRGB: devices.lights.spectrumRGB
            }
          }
        }
      }
    };
    res.status(200).json(deviceStates);
  });
}

function execute(reqdata, res) {
  getDevicesDataFromFirebase(devices => {
    let reqCommands = reqdata.inputs[0].payload.commands
    let respCommands = [];

    for (let i = 0; i < reqCommands.length; i++) {
      let curCommand = reqCommands[i];
      for (let j = 0; j < curCommand.execution.length; j++) {
        let curExec = curCommand.execution[j];
        console.log('> curExec ', curExec);
        if (curExec.command === "action.devices.commands.OnOff") {
          for (let k = 0; k < curCommand.devices.length; k++) {
            let curDevice = curCommand.devices[k];
            if (curDevice.id === "1") {
              devices.fan.on = curExec.params.on;
            } else if (curDevice.id === "2") {
              devices.lights.on = curExec.params.on;
            }
            respCommands.push({ids: [ curDevice.id ], status: "SUCCESS"});
          }
        } else if (curExec.command === "action.devices.commands.ColorAbsolute") {
          for (let k = 0; k < curCommand.devices.length; k++) {
            let curDevice = curCommand.devices[k];
            if (curDevice.id === "2") {
              devices.lights.spectrumRGB = curExec.params.color.spectrumRGB;
            }
            respCommands.push({ids: [ curDevice.id ], status: "SUCCESS"});
          }
        }
      }
    }

    persistDevicesDataToFirebase(devices);

    let resBody = {
      requestId: reqdata.requestId,
      payload: {
        commands: respCommands
      }
    };
    res.status(200).json(resBody);
  });
}

function showError(res, message) {
  res.status(401).set({
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
  }).json({error: message});
}

function getDevicesDataFromFirebase(action) {
  admin.database().ref().once("value", snapshot => {
    let devices = snapshot.val();
    action(devices);
  });
}

function persistDevicesDataToFirebase(data) {
  admin.database().ref().set(data);
}

// [END all]
