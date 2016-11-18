angular.module('app.controllers.home', [])

.controller('homeCtrl', function($ionicPlatform, $scope, PushService, FirebaseService) {
  console.log('homeCtrl');

  var fb_init = localStorage.getItem('firebase_init');
  if (fb_init == 'true') {

    FirebaseService.init();

    $scope.control = {};
    $scope.status = {};

    // wait for device ready (cordova) before initialize push service
    $ionicPlatform.ready(function() {
      PushService.init();
    });

    $scope.pushCtrl0Change = function() {
      var ref = firebase.database().ref("control");
      if ($scope.control.alarm) {
        ref.update({
          alarm: true
        });
      } else {
        ref.update({
          alarm: false
        });
      }
    };

    $scope.pushCtrl1Change = function() {
      var ref = firebase.database().ref("control");
      if ($scope.control.led) {
        ref.update({
          led: true
        });
      } else {
        ref.update({
          led: false
        });
      }
    };

    $scope.pushCtrl2Change = function() {
      var ref = firebase.database().ref("control");
      if ($scope.control.reboot) {
        ref.update({
          reboot: true
        });
      } else {
        ref.update({
          reboot: false
        });
      }
    };

    $scope.pushCtrl3Change = function() {
      var ref = firebase.database().ref("control");
      if ($scope.control.monitor) {
        ref.update({
          monitor: true
        });
      } else {
        ref.update({
          monitor: false
        });
      }
    };

    $scope.doRefresh = function() {
      console.log('doRefresh-HomeCtrl');
      var ref = firebase.database().ref("/");
      // Attach an asynchronous callback to read the data at our posts reference
      ref.on('value', function(snapshot) {
        var payload = snapshot.val();
        $scope.control = payload.control;
        $scope.status = payload.status;
      }, function(errorObject) {
        console.log("firebase failed: " + errorObject.code);
      });
      $scope.$broadcast('scroll.refreshComplete');
      $scope.$broadcast("scroll.infiniteScrollComplete");
    };

    $scope.doRefresh();
  } else {
    console.log('Firebase not initialized');
    alert('Firebase not initialized');
    $scope.$broadcast('scroll.refreshComplete');
  }
})
