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

        var fb_url = localStorage.getItem('firebase_url');
        var fb_secret = localStorage.getItem('fb_secret');
        var firebase_server_key = localStorage.getItem('firebase_server_key');
        config.databaseURL = "https://" + fb_url;
        firebase.initializeApp(config);

        // var fb_secret = localStorage.getItem('firebase_secret');
        // console.log(fb_secret);
        // firebase.auth().signInWithCustomToken(fb_secret).catch(function(error) {
        //   // Handle Errors here.
        //   var errorCode = error.code;
        //   var errorMessage = error.message;
        //   // ...
        // });
      }
    }
  }

  return service;
})
