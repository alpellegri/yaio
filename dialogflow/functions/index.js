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

const Assistant = require('actions-on-google').ApiAiAssistant;
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// API.AI Intent names
const PLAY_INTENT = 'play';
const NO_INTENT = 'discriminate-no';
const YES_INTENT = 'discriminate-yes';
const GIVEUP_INTENT = 'give-up';
const LEARN_THING_INTENT = 'learn-thing';
const LEARN_DISCRIM_INTENT = 'learn-discrimination';

// Contexts
const WELCOME_CONTEXT = 'welcome';
const QUESTION_CONTEXT = 'question';
const GUESS_CONTEXT = 'guess';
const LEARN_THING_CONTEXT = 'learn-thing';
const LEARN_DISCRIM_CONTEXT = 'learn-discrimination';
const ANSWER_CONTEXT = 'answer';

// Context Parameters
const VALUE_PARAM = 'digital_value';
const RESOURCE_PARAM = 'resource';
const LEARN_THING_PARAM = 'learn-thing';
const GUESSABLE_THING_PARAM = 'guessable-thing';
const LEARN_DISCRIMINATION_PARAM = 'learn-discrimination';
const ANSWER_PARAM = 'answer';
const QUESTION_PARAM = 'question';

exports.assistantcodelab = functions.https.onRequest((request, response) => {
  console.log('headers: ' + JSON.stringify(request.headers));
  console.log('body: ' + JSON.stringify(request.body));

  const assistant = new Assistant({request: request, response: response});

  let actionMap = new Map();
  actionMap.set(PLAY_INTENT, play);
  assistant.handleRequest(actionMap);

  function play(assistant) {
	const resource = assistant.getContextArgument(WELCOME_CONTEXT, RESOURCE_PARAM).value;
	const value = assistant.getContextArgument(WELCOME_CONTEXT, VALUE_PARAM).value;
    console.log('play');
    console.log(resource);
    console.log(value);
	var speech;
	if (resource == 'alarm') {
	  if (value == 'off') {
		speech = `ok I will set ${resource} ${value}`;
        var current_date = new Date();
        admin.database().ref('control/time').set(Math.floor(current_date.getTime() / 1000));
		admin.database().ref('/control/alarm').set(false);
	  } else if (value == 'on') {
		speech = `ok I will set ${resource} ${value}`; 
        var current_date = new Date();
        admin.database().ref('control/time').set(Math.floor(current_date.getTime() / 1000));
		admin.database().ref('/control/alarm').set(true);
	  } else {
		   speech = `sorry this action is not available`;
	  }
    } else {
	  speech = `sorry this action is not available`;
    }

	   assistant.ask(speech);
   }
});
