angular.module('app.services.firebase', [])

  .factory('FirebaseService', function($ionicPlatform, $rootScope, $http, PushService) {
    console.log('FirebaseService: InitFirebase');

    var service_init_done = false;
    var service = {};
    service.init = function() {
      service.status = false;
      if (service_init_done == false) {
        service_init_done = true;
        var fb_user_init = localStorage.getItem('firebase_user_init');
        if (fb_user_init == 'true') {
          $http.get('google-services.json')
            .success(function(data) {
              var config = {
                apiKey: "",
                authDomain: "",
                databaseURL: "",
                storageBucket: "",
                messagingSenderId: ""
              };
              console.log('google-services.json');
              console.log(data);
              // The json data will now be in scope.
              service.google_services = data;
              config.apiKey = service.google_services.client[0].api_key[0].current_key;
              config.databaseURL = service.google_services.project_info.firebase_url;
              config.messagingSenderId = service.google_services.project_info.project_number;
              firebase.initializeApp(config);
              var fb_username = localStorage.getItem('firebase_username');
              var fb_password = localStorage.getItem('firebase_password');
              firebase.auth().signInWithEmailAndPassword(fb_username, fb_password).catch(function(error) {
                console.log('auth error');
                alert('Firebase Authentication Error');
                // Handle Errors here.
                var errorCode = error.code;
                var errorMessage = error.message;
                // ...
              });
              service.status = true;
              $ionicPlatform.ready(function() {
                PushService.init(config.messagingSenderId);
              });
            });
        }
      }
    }

    service.up = function() {
      console.log("service.up: " + service.status);
      return service.status;
    }

    service.GetmessagingSenderId = function() {
      return service.google_services.project_info.project_number;
    }

    return service;
  })
