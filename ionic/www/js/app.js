// Ionic Starter App

angular.module('app', ['ionic', 'chart.js',
  'app.services',
  'app.services.firebase',
  'app.services.websocket',
  'app.services.push',
  'app.controllers.home',
  'app.controllers.NodeSetup',
  'app.controllers.RadioSetup',
  'app.controllers.chart',
  'app.controllers.FirebaseSetup',
  'app.controllers.History',
  'app.controllers.NodeInfo',
  'app.routes', 'app.directives',
  'ngCordova'
])

.run(function($ionicPlatform) {
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
