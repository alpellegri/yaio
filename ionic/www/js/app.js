// Ionic Starter App

angular.module('app', ['ionic', 'chart.js',
  'app.services', 'app.controllers', 'app.routes', 'app.directives',
  'ngCordova'
])

.run(function($ionicPlatform) {

  // var config = {
  //   apiKey: "",
  //   authDomain: "",
  //   databaseURL: "",
  //   storageBucket: "",
  //   messagingSenderId: ""
  // };
  //
  // var fb_url = localStorage.getItem('firebase_url');
  // var fb_secret = localStorage.getItem('fb_secret');
  // var firebase_server_key = localStorage.getItem('firebase_server_key');
  // config.databaseURL = "https://" + fb_url;
  // firebase.initializeApp(config);

  // var fb_secret = localStorage.getItem('firebase_secret');
  // console.log(fb_secret);
  // firebase.auth().signInWithCustomToken(fb_secret).catch(function(error) {
  //   // Handle Errors here.
  //   var errorCode = error.code;
  //   var errorMessage = error.message;
  //   // ...
  // });

  $ionicPlatform.ready(function() {
    // Hide the accessory bar by default (remove this to show the accessory bar above the keyboard
    // for form inputs)
    if (window.cordova && window.cordova.plugins && window.cordova.plugins.Keyboard) {
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true);
      cordova.plugins.Keyboard.disableScroll(true);
    }
    if (window.StatusBar) {
      // org.apache.cordova.statusbar required
      StatusBar.styleDefault();
    }
  });
});

angular.module('app.controllers', []);
angular.module('app.service', []);
