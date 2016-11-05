// Ionic Starter App

angular.module('app', ['ionic', 'chart.js', 'app.controllers', 'app.routes', 'app.services', 'app.directives', 'ngCordova'])

.run(function($ionicPlatform) {

  var config = {
    apiKey: "AIzaSyBqJWOLi2b0SQJ51Ug0U6hKF5lDBVkRCIQ",
    authDomain: "ikka.firebaseapp.com",
    databaseURL: "https://ikka.firebaseio.com",
    storageBucket: "project-7110587599444694745.appspot.com",
    messagingSenderId: "110645288431"
  };

  var fb_url = localStorage.getItem('firebase_url');
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
})
