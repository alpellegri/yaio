angular.module('app.services', [])

.factory('BlankFactory', [function() {

}])

.service('BlankService', [function() {

}])

.factory('serviceLog', function() {
  var logsText = '';
  return {
    putlog: function(message) {
      console.log(message);
      logsText += message + '\n';
      return;
    },
    getlog: function() {
      return logsText;
    }
  }
})

.factory('WebSocketService', function() {
  var service = {};

  service.connect = function() {
    // if (service.ws) { return; }

    var wsUri = "ws://192.168.2.1:81/";
    var ws = new WebSocket(wsUri);

    ws.onopen = function() {
      service.open_cb();
    };

    ws.onclose = function() {
      service.close_cb();
    };

    ws.onerror = function() {
      service.error_cb();
    }

    ws.onmessage = function(message) {
      service.message_cb(message.data);
    };

    service.ws = ws;
  }

  service.disconnect = function() {
    service.ws.close();
  }

  service.send = function(message) {
    service.ws.send(message);
  }

  service.subscribe = function(open_cb, close_cb, error_cb, message_cb) {
    service.open_cb = open_cb;
    service.close_cb = close_cb;
    service.error_cb = error_cb;
    service.message_cb = message_cb;
  }

  return service;
})

.factory('PushService', function($ionicPlatform, $rootScope, $http, $cordovaPushV5) {
  var service = {};

  $ionicPlatform.ready(function() {

    service.init = function() {

      var options = {
        android: {
          "clearNotifications": false,
          "senderID": "110645288431"
        },
        ios: {
          alert: "true",
          badge: "true",
          sound: "true"
        },
        windows: {}
      };

      if (ionic.Platform.isAndroid() == true) {
        // initialize
        $cordovaPushV5.initialize(options).then(function() {
          // start listening for new notifications
          $cordovaPushV5.onNotification();
          // start listening for errors
          $cordovaPushV5.onError();

          // register to get registrationId
          $cordovaPushV5.register().then(function(token) {
            // `data.registrationId` save it somewhere;
            console.log(token);
            var oldRegId = localStorage.getItem('registrationId');
            if (oldRegId !== token) {
              // Save new registration ID
              localStorage.setItem('registrationId', token);
              console.log('store registrationId to firebase DB');
              // Post registrationId to your app server as the value has changed
              var ref = new Firebase("https://ikka.firebaseIO.com");
              var FCM_Registration_IDs_ref = ref.child('FCM_Registration_IDs');
              FCM_Registration_IDs_ref.push(token);
            }
          })
        });

        // triggered every time notification received
        $rootScope.$on('$cordovaPushV5:notificationReceived', function(event, data) {
          // console.log(data);
          // data.message,
          // data.title,
          // data.count,
          // data.sound,
          // data.image,
          // data.additionalData
          console.log('notification event');
          console.log(data);
          alert('Title: ' + data.title.toString() + '\n' + 'Message: ' + data.message.toString());
        });

        // triggered every time error occurs
        $rootScope.$on('$cordovaPushV5:errorOcurred', function(event, e) {
          // e.message
        });
      }
    }
  });

  return service;
})
