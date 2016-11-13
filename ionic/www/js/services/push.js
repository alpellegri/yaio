angular.module('app.services.push', [])

.factory('PushService', function($ionicPlatform, $rootScope, $http, $cordovaPushV5) {
  var service = {};

  console.log('services');
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
              var ref = firebase.database().ref("/");
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
