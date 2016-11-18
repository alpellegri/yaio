angular.module('app.services.firebase', [])

.factory('FirebaseService', function() {
  console.log('FirebaseService: InitFirebase');

  var service_init_done = false;
  var service = {};
  service.init = function() {
    if (service_init_done == false) {
      service_init_done = true;
      var fb_init = localStorage.getItem('firebase_init');
      // console.log('FirebaseService firebase_init');
      // console.log(fb_init);
      if (fb_init == 'true') {
        var config = {
          apiKey: "",
          authDomain: "",
          databaseURL: "",
          storageBucket: "",
          messagingSenderId: ""
        };

        var fb_api_key = localStorage.getItem('firebase_api_key');
        var fb_url = localStorage.getItem('firebase_url');
        config.apiKey = fb_api_key;
        config.databaseURL = fb_url;
        firebase.initializeApp(config);

        var fb_username = localStorage.getItem('firebase_username');
        var fb_password = localStorage.getItem('firebase_password');
        // firebase.auth().createUserWithEmailAndPassword('alessio.pellegrinetti@gmail.com', 'slayer123').catch(function(error) {
        //   console.log('create error');
        //   // Handle Errors here.
        //   var errorCode = error.code;
        //   var errorMessage = error.message;
        //   // ...
        // });
        firebase.auth().signInWithEmailAndPassword(fb_username, fb_password).catch(function(error) {
          console.log('auth error');
          // Handle Errors here.
          var errorCode = error.code;
          var errorMessage = error.message;
          // ...
        });
      }
    }
  }

  return service;
})
