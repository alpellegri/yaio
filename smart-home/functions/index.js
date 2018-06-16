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
const {smarthome} = require('actions-on-google');
const cors = require('cors')({origin: true});

// Initialize Firebase
const config = functions.config().firebase;
const admin = require('firebase-admin');
admin.initializeApp();

const oauth2Ref = admin.database().ref('/oauth2');

exports.auth = functions.https.onRequest((request, response) => {
  // console.log('auth -> Request headers: ' + JSON.stringify(request.headers));
  // console.log('auth -> Request query: ' + JSON.stringify(request.query));
  // console.log('auth -> Request body: ' + JSON.stringify(request.body));

  // Code entry.
  let Data = {
    value: 0,
    uid: request.query.code,
    state: request.query.state,
  };

  let Key = request.query.code;
  let updates = {};
  updates['/auth_code/' + Key] = Data;
  // should wait the it returns...
  oauth2Ref.update(updates);

	const responseurl = util.format('%s?code=%s&state=%s',
    decodeURIComponent(request.query.redirect_uri),
    request.query.code,
    request.query.state);
  console.log('-> responseurl: ' + responseurl);
  return response.redirect(responseurl);
});

exports.token = functions.https.onRequest((request, response) => {
  // console.log('token -> Request headers: ' + JSON.stringify(request.headers));
  // console.log('token -> Request query: ' + JSON.stringify(request.query));
  // console.log('token -> Request body: ' + JSON.stringify(request.body));

  const grantType = request.query.grant_type
    ? request.query.grant_type : request.body.grant_type;
  const expires = 1 * 60 * 60;
  const HTTP_STATUS_OK = 200;
  console.log(`Grant type ${grantType}`);

  if (grantType === 'authorization_code') {
    console.log(`request.body.code ${request.body.code}`);
    oauth2Ref.child('auth_code').child(request.body.code).once('value').then(function(snapshot) {
      const auth_code = snapshot.val();
      const obj = {
        token_type: 'bearer',
        access_token: auth_code.uid,
        refresh_token: auth_code.uid,
        expires_in: expires,
      };
      const Data = {
        value: 0,
        uid: auth_code.uid,
        expires: expires,
      };
      const Key = auth_code.uid;
      let updates = {};
      updates['/access_token/' + Key] = Data;
      updates['/refresh_token/' + Key] = Data;
      // should wait the it returns...
      oauth2Ref.update(updates);
      response.status(HTTP_STATUS_OK).json(obj);
    }).catch((err) => {
      console.error(err);
    });
  } else if (grantType === 'refresh_token') {
    console.log(`request.body.refresh_token ${request.body.refresh_token}`);
    oauth2Ref.child('refresh_token').child(request.body.refresh_token).once('value').then(function(snapshot) {
      const refresh_token = snapshot.val();
      const obj = {
        token_type: 'bearer',
        access_token: refresh_token.uid,
        expires_in: expires,
      };
      const Data = {
        value: 0,
        uid: refresh_token.uid,
        expires: expires,
      };
      const Key = refresh_token.uid;
      let updates = {};
      updates['/access_token/' + Key] = Data;
      oauth2Ref.update(updates);
      response.status(HTTP_STATUS_OK).json(obj);
    }).catch((err) => {
      console.error(err);
    });
  }
});

function init(req, res, uid, domains, uidRef) {
  let reqdata = req.body;

  if (!reqdata.inputs) {
    showError(res, 'missing inputs');
    return;
  }

  for (let i = 0; i < reqdata.inputs.length; i++) {
    let input = reqdata.inputs[i];
		let intent = input.intent || '';
		console.log('> intent ', intent);
    switch (intent) {
      case 'action.devices.SYNC':
        sync(reqdata, res, uid, domains, uidRef);
        return;
      case 'action.devices.QUERY':
        query(reqdata, res, uid, domains, uidRef);
        return;
      case 'action.devices.EXECUTE':
        execute(reqdata, res, uid, domains, uidRef);
        return;
    }
  }
  showError(res, 'missing intent');
}

function sync(req, res, uid, domains, uidRef) {

  uidRef.child('/obj/data').child(domains[0]).once('value').then(function(snapshot) {
    const snapshotVal = snapshot.val();
    const device_keys = Object.keys(snapshotVal);
    let devices = [];
    for (let i = 0; i < device_keys.length; i++) {
      let type = 'action.devices.types.SWITCH';
      let trait = 'action.devices.traits.OnOff';
      devices[i] = {
        id: device_keys[i],
        type: type,
        traits: [
          trait,
        ],
        name: {
          defaultNames: [device_keys[i]],
          name: device_keys[i],
          nicknames: [device_keys[i]],
        },
        willReportState: false,
        deviceInfo: {
          manufacturer: 'Yaio',
          model: 'yaio virtual device',
          hwVersion: '1.0',
          swVersion: '1.0.1',
        },
      };
    }

    let json = {
      requestId: req.requestId,
      payload: {
        agentUserId: uid,
        devices: devices,
      },
    };
    // console.log('-> json: ' + JSON.stringify(json));
    res.status(200).json(json);
  }).catch((err) => {
    console.error(err);
    showError(res, 'database error');
  });
}

function query(req, res, uid, domains, uidRef) {

  uidRef.child('/obj/data').child(domains[0]).once('value').then(function(snapshot) {
    const snapshotVal = snapshot.val();
    const device_keys = Object.keys(snapshotVal);
    const reqDevices = req.inputs[0].payload.devices;

    let devices = {};
    for (let i = 0; i < reqDevices.length; i++) {
      let id = device_keys.indexOf(reqDevices[i].id);
      if (id != -1) {
        let value = (snapshotVal[device_keys[id]].value != 0) ? true : false;
        devices[device_keys[id]] = {
          on: value,
          online: true,
        };
      }
    }

    let json = {
      requestId: req.requestId,
      payload: {
        devices: devices,
      },
    };
    // console.log('-> json: ' + JSON.stringify(json));
    res.status(200).json(json);
  }).catch((err) => {
    console.error(err);
    showError(res, 'database error');
  });
}

function execute(body, res, uid, domains, uidRef) {

  const {requestId} = body;
  const payload = {
    commands: [{
      ids: [],
      status: 'SUCCESS',
      states: {
        online: true,
      },
    }],
  };

  uidRef.child('/obj/data').child(domains[0]).once('value').then(function(snapshot) {
    const snapshotVal = snapshot.val();
    const device_keys = Object.keys(snapshotVal);

    for (const input of body.inputs) {
      for (let k = 0; k < input.payload.commands.length; k++) {
        const command = input.payload.commands[k];
        for (const device of command.devices) {
          const deviceId = device.id;
          const id = device_keys.indexOf(deviceId);
          payload.commands[k].ids.push(deviceId);
          if (id != -1) {
            for (const execution of command.execution) {
              const execCommand = execution.command;
              const {params} = execution;
              const value = (params.on == true) ? 1 : 0;
              let val = snapshotVal[device_keys[id]].value;
              // clear last significant bit and set
              val = (val & (~1)) | value;
              let d = new Date();
              switch (execCommand) {
                case 'action.devices.commands.OnOff':
                  uidRef.child('/obj/data').child(domains[0]).child(device_keys[id]).update({
                    value: val,
                  });
                  uidRef.child('/root').child(domains[0]).child(snapshotVal[device_keys[id]].owner).child('control').update({
                    time: Math.floor(d.getTime()/1000),
                  });
                  payload.commands[0].states.on = params.on;
                  break;
              }
            }
          }
        }
      }
    }

    let json = {
      requestId: requestId,
      payload: payload,
    };
    // console.log('-> json: ' + JSON.stringify(json));
    res.status(200).json(json);
  }).catch((err) => {
    console.error(err);
    showError(res, 'database error');
  });
}

function showError(res, message) {
  res.status(401).set({
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
  }).json({error: message});
}

exports.ha = functions.https.onRequest((req, res) => {
  // console.log('-> Request headers: ' + JSON.stringify(req.headers));
  // console.log('-> Request query: ' + JSON.stringify(req.query));
  // console.log('-> Request body: ' + JSON.stringify(req.body));

  let access_token = req.headers.authorization ? req.headers.authorization.split(' ')[1] : null;
  console.log('access_token: ' + access_token);

  // for now uid is access_token
  const uid = access_token;

  const uidPath = '/users/' + uid;
  const uidRef = admin.database().ref(uidPath);

  uidRef.child('/root').once('value').then(function(snapshot) {
    const snapshotVal = snapshot.val();
    const domains = Object.keys(snapshotVal);
    if (domains.length > 0) {
      init(req, res, uid, domains, uidRef);
    } else {
      showError(res, 'database error');
    }
  }).catch((err) => {
    console.error(err);
    showError(res, 'database error');
  });
});
