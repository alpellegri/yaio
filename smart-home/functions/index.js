/**
 * Copyright 2018 Google Inc. All Rights Reserved.
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

const functions = require('firebase-functions');
const { smarthome } = require('actions-on-google');
const { google } = require('googleapis');
const util = require('util');
const admin = require('firebase-admin');

// Initialize Firebase
admin.initializeApp();
const firebaseRef = admin.database().ref('/');

// Initialize Homegraph
const auth = new google.auth.GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/homegraph']
});
const homegraph = google.homegraph({
  version: 'v1',
  auth: auth
});

const oauth2Ref = admin.database().ref('/oauth2');

const kCodeTemperature = 2;
const kCodeHumidity = 3;
const kCodeBool = 8;

exports.fakeauth = functions.https.onRequest((request, response) => {
  // functions.logger.log('fakeauth -> Request headers: ' + JSON.stringify(request.headers));
  // functions.logger.log('fakeauth -> Request query: ' + JSON.stringify(request.query));
  // functions.logger.log('fakeauth -> Request body: ' + JSON.stringify(request.body));

  // Code entry.
  let data = {
    value: 0,
    uid: request.query.code,
    state: request.query.state,
  };

  let key = request.query.code;
  let updates = {};
  updates['/auth_code/' + key] = data;
  // should wait the it returns...
  oauth2Ref.update(updates);

  const responseurl = util.format('%s?code=%s&state=%s',
    decodeURIComponent(request.query.redirect_uri),
    request.query.code,
    request.query.state);
  functions.logger.log('fakeauth -> responseurl: ' + responseurl);
  return response.redirect(responseurl);
});

exports.faketoken = functions.https.onRequest(async (request, response) => {
  // functions.logger.log('faketoken -> Request headers: ' + JSON.stringify(request.headers));
  // functions.logger.log('faketoken -> Request query: ' + JSON.stringify(request.query));
  // functions.logger.log('faketoken -> Request body: ' + JSON.stringify(request.body));

  const grantType = request.query.grant_type
    ? request.query.grant_type : request.body.grant_type;
  const secondsInDay = 86400; // 86400 = 60 * 60 * 24
  const HTTP_STATUS_OK = 200;
  functions.logger.log(`faketoken -> Grant type ${grantType}`);

  if (grantType === 'authorization_code') {
    functions.logger.log(`faketoken -> request.body.code ${request.body.code}`);
    const snapshot = await oauth2Ref.child('auth_code').child(request.body.code).once('value');
    const auth_code = snapshot.val();
    const obj = {
      token_type: 'bearer',
      access_token: auth_code.uid,
      refresh_token: auth_code.uid,
      expires_in: secondsInDay,
    };
    const data = {
      value: 0,
      uid: auth_code.uid,
      expires: secondsInDay,
    };
    const key = auth_code.uid;
    let updates = {};
    updates['/access_token/' + key] = data;
    updates['/refresh_token/' + key] = data;
    // should wait the it returns...
    oauth2Ref.update(updates);
    response.status(HTTP_STATUS_OK).json(obj);
  } else if (grantType === 'refresh_token') {
    functions.logger.log(`faketoken -> request.body.refresh_token ${request.body.refresh_token}`);
    const snapshot = await oauth2Ref.child('refresh_token').child(request.body.refresh_token).once('value');
    const refresh_token = snapshot.val();
    const obj = {
      token_type: 'bearer',
      access_token: refresh_token.uid,
      expires_in: secondsInDay,
    };
    const data = {
      value: 0,
      uid: refresh_token.uid,
      expires: secondsInDay,
    };
    const key = refresh_token.uid;
    let updates = {};
    updates['/access_token/' + key] = data;
    oauth2Ref.update(updates);
    response.status(HTTP_STATUS_OK).json(obj);
  }
});

const app = smarthome({
  debug: false,
});

app.onSync(async (body, headers) => {
  // functions.logger.log('onSync -> body: ' + JSON.stringify(body));
  // functions.logger.log('onSync -> headers: ' + JSON.stringify(headers));

  const access_token = headers.authorization ? headers.authorization.split(' ')[1] : null;
  const uid = access_token;
  const uidPath = '/users/' + uid;
  const uidRef = admin.database().ref(uidPath);
  const snapshot = await uidRef.child('/obj/data').once('value');
  const snapshotVal = snapshot.val();

  let devices = [];
  if (snapshotVal) {
    // functions.logger.log('onSync -> snapshotVal: ' + JSON.stringify(snapshotVal));
    const domains = Object.entries(snapshotVal);
    for (const [domain, domainData] of domains) {
      const keys = Object.entries(domainData);
      for (const [key, keyData] of keys) {
        if (keyData.aog == true) {
          if (keyData.code == kCodeBool) {
            // const json = JSON.stringify(keyData);
            // functions.logger.log(`onSync -> ${domain} -> ${key} : ${json}`)
            const data = {
              id: domain + '/' + key,
              type: 'action.devices.types.SWITCH',
              traits: [
                'action.devices.traits.OnOff',
              ],
              name: {
                defaultNames: [key],
                name: key,
                nicknames: [key],
              },
              willReportState: true,
              deviceInfo: {
                manufacturer: 'Yaio',
                model: 'yaio virtual device',
                hwVersion: '1.0',
                swVersion: '1.0.1',
              },
            }
            devices.push(data);
          } else if (keyData.code == kCodeTemperature) {
            // const json = JSON.stringify(keyData);
            // functions.logger.log(`onSync -> ${domain} -> ${key} : ${json}`)
            const data = {
              id: domain + '/' + key,
              type: 'action.devices.types.THERMOSTAT',
              traits: [
                'action.devices.traits.TemperatureSetting',
              ],
              name: {
                defaultNames: [key],
                name: key,
                nicknames: [key],
              },
              willReportState: true,
              attributes: {
                queryOnlyTemperatureSetting: true,
                thermostatTemperatureUnit: 'C',
              },
              deviceInfo: {
                manufacturer: 'Yaio',
                model: 'yaio virtual device',
                hwVersion: '1.0',
                swVersion: '1.0.1',
              },
            }
            devices.push(data);
          } else if (keyData.code == kCodeHumidity) {
            // const json = JSON.stringify(keyData);
            // functions.logger.log(`onSync -> ${domain} -> ${key} : ${json}`)
            const data = {
              id: domain + '/' + key,
              type: 'action.devices.types.THERMOSTAT',
              traits: [
                'action.devices.traits.TemperatureSetting',
              ],
              name: {
                defaultNames: [key],
                name: key,
                nicknames: [key],
              },
              willReportState: true,
              attributes: {
                queryOnlyHumiditySetting: true,
              },
              deviceInfo: {
                manufacturer: 'Yaio',
                model: 'yaio virtual device',
                hwVersion: '1.0',
                swVersion: '1.0.1',
              },
            }
            devices.push(data);
          }
        }
      }
    }
  }

  const resp = {
    requestId: body.requestId,
    payload: {
      agentUserId: uid,
      devices: devices,
    },
  };

  return resp;
});

const queryFirebase = async (uid, deviceId) => {
  const uidPath = '/users/' + uid;
  const uidRef = admin.database().ref(uidPath);
  const domain = deviceId.split('/')[0];
  const device = deviceId.split('/')[1];
  const path = `/obj/data/${domain}/${device}`;
  const snapshot = await uidRef.child(path).once('value');
  const data = snapshot.val();

  let resp;
  switch (data.code) {
    case kCodeTemperature:
      // functions.logger.log('queryFirebase -> kCodeTemperature: ' + data.value);
      resp = {
        status: 'SUCCESS',
        online: true,
        on: true,
        thermostatTemperatureAmbient: data.value,
      };
      break;
    case kCodeHumidity:
      // functions.logger.log('queryFirebase -> kCodeHumidity: ' + data.value);
      resp = {
        status: 'SUCCESS',
        online: true,
        on: true,
        thermostatHumidityAmbient: data.value,
      };
      break;
    case kCodeBool:
      // functions.logger.log('queryFirebase -> kCodeBool: ' + data.value);
      resp = {
        status: 'SUCCESS',
        online: true,
        on: data.value,
      };
      break;
  }

  return resp;
}

const queryDevice = async (uid, deviceId) => {
  // functions.logger.log('queryDevice -> queryDevice: ' + JSON.stringify(deviceId));
  const resp = await queryFirebase(uid, deviceId);
  return resp;
}

app.onQuery(async (body, headers) => {
  // functions.logger.log('onQuery -> body: ' + JSON.stringify(body));
  // functions.logger.log('onQuery -> headers: ' + JSON.stringify(headers));

  const access_token = headers.authorization ? headers.authorization.split(' ')[1] : null;
  const uid = access_token;

  const { requestId } = body;
  const payload = {
    devices: {},
  };
  const queryPromises = [];
  const intent = body.inputs[0];
  for (const device of intent.payload.devices) {
    const deviceId = device.id;
    queryPromises.push(queryDevice(uid, deviceId)
      .then((data) => {
        // Add response to device payload
        payload.devices[deviceId] = data;
      }
      ));
  }
  // Wait for all promises to resolve
  await Promise.all(queryPromises)
  return {
    requestId: requestId,
    payload: payload,
  };
});

const updateDevice = async (execution, uid, deviceId) => {
  const { params, command } = execution;

  const uidPath = '/users/' + uid;
  const uidRef = admin.database().ref(uidPath);
  const domain = deviceId.split('/')[0];
  const device = deviceId.split('/')[1];
  const path = `/obj/data/${domain}/${device}`;

  let state, ref;
  switch (command) {
    case 'action.devices.commands.OnOff':
      state = { value: params.on };
      ref = uidRef.child(path);
      break;
    // case 'action.devices.commands.StartStop':
    // state = {isRunning: params.start};
    // ref = firebaseRef.child(deviceId).child('StartStop');
    // break;
    // case 'action.devices.commands.PauseUnpause':
    // state = {isPaused: params.pause};
    // ref = firebaseRef.child(deviceId).child('StartStop');
    // break;
  }

  return ref.update(state)
    .then(() => state);
};

const updateRoot = async (uid, domain, node) => {
  const uidPath = '/users/' + uid;
  const uidRef = admin.database().ref(uidPath);
  const path = `/root/${domain}/${node}/control`;

  const d = new Date();
  let state, ref;
  state = { time: Math.floor(d.getTime() / 1000) };
  ref = uidRef.child(path);

  return ref.update(state)
    .then(() => state);
};

app.onExecute(async (body, headers) => {
  // functions.logger.log('onExecute -> body: ' + JSON.stringify(body));
  // functions.logger.log('onExecute -> headers: ' + JSON.stringify(headers));

  const access_token = headers.authorization ? headers.authorization.split(' ')[1] : null;
  const uid = access_token;
  const uidPath = '/users/' + uid;
  const uidRef = admin.database().ref(uidPath);

  const { requestId } = body;
  // Execution results are grouped by status
  const result = {
    ids: [],
    status: 'SUCCESS',
    states: {
      online: true,
    },
  };

  const executePromises = [];
  const intent = body.inputs[0];
  for (const command of intent.payload.commands) {
    for (const device of command.devices) {
      const deviceId = device.id;
      for (const execution of command.execution) {
        const domain = deviceId.split('/')[0];
        const device = deviceId.split('/')[1];

        const snapshot = await uidRef.child('/obj/data').child(domain).child(device).once('value');
        const snapshotVal = snapshot.val();
        // functions.logger.log('onExecute -> snapshot: ' + JSON.stringify(snapshot));
        const node = snapshotVal.owner;

        executePromises.push(
          updateDevice(execution, uid, deviceId)
            .then((data) => {
              result.ids.push(deviceId);
              Object.assign(result.states, data);
            })
            .catch(() => functions.logger.error(`Unable to update ${device.id}`))
        );
        executePromises.push(
          updateRoot(uid, domain, node)
            .then((data) => { })
            .catch(() => functions.logger.error(`Unable to root ${device.id}`))
        );
      }
    }
  }


  await Promise.all(executePromises)
  return {
    requestId: requestId,
    payload: {
      commands: [result],
    },
  };
});

exports.smarthome = functions.https.onRequest(app);

exports.requestsync = functions.https.onRequest(async (request, response) => {
  // functions.logger.log('requestsync -> request: ' + JSON.stringify(request));
  response.set('Access-Control-Allow-Origin', '*');
  // functions.logger.info('requestsync -> Request SYNC for user 123');
  try {
    const res = await homegraph.devices.requestSync({
      requestBody: {
        agentUserId: '123'
      }
    });
    functions.logger.info('requestsync -> Request sync response:', res.status, res.data);
    response.json(res.data);
  } catch (err) {
    functions.logger.error(err);
    response.status(500).send(`Error requesting sync: ${err}`)
  }
});

/**
 * Send a REPORT STATE call to the homegraph when data for any device id
 * has been changed.
 */

// exports.reportstate = functions.database.ref('{deviceId}').onWrite(async (change, context) => {
//   functions.logger.info('Firebase write event triggered this cloud function');
//   const snapshot = change.after.val();
//   // functions.logger.info(JSON.stringify(change));
//   // functions.logger.info(JSON.stringify(context));
//
//   const requestBody = {
//     requestId: 'ff36a3cc', /* Any unique ID */
//     agentUserId: '123', /* Hardcoded user ID */
//     payload: {
//       devices: {
//         states: {
//           /* Report the current state of our washer */
//           [context.params.deviceId]: {
//             on: snapshot.OnOff.on,
//             isPaused: snapshot.StartStop.isPaused,
//             isRunning: snapshot.StartStop.isRunning,
//           },
//         },
//       },
//     },
//   };
//
//   const res = await homegraph.devices.reportStateAndNotification({
//     requestBody
//   });
//   functions.logger.info('Report state response:', res.status, res.data);
// });

