angular.module('app.services.push', [])

  .factory('PushService', function($ionicPlatform, $rootScope, $http, $cordovaPushV5) {
    var service = {};

    console.log('services');
    $ionicPlatform.ready(function() {
      service.init = function(messagingSenderId) {

        var options = {
          android: {
            "clearNotifications": false,
            "senderID": "XXXXXXXXXXX"
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
          options.android.senderID = messagingSenderId;//FirebaseService.GetmessagingSenderId();

          $cordovaPushV5.initialize(options).then(function() {
            // start listening for new notifications
            $cordovaPushV5.onNotification();
            // start listening for errors
            $cordovaPushV5.onError();

            // register to get registrationId
            $cordovaPushV5.register().then(function(token) {
              // `data.registrationId` save it somewhere;
              console.log('FCM token: ' + token);
              var tokenIDfound = false;
              var ref = firebase.database().ref('FCM_Registration_IDs');
              ref.on('value', function(snapshot) {
                var RegIDs = snapshot;
                RegIDs.forEach(function(id) {
                  if (id.val() == token) {
                    tokenIDfound = true;
                  }
                })
                console.log('token ID found: ' + tokenIDfound);
                if (tokenIDfound == false) {
                  // token not found. push it
                  ref.push(token);
                  console.log('token registered');
                }
              });
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
            console.log('$cordovaPushV5:errorOcurred: ' + e.message);
          });
        }
      }
    });

    return service;
  })
