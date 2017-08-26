angular.module('app.controllers.home', [])

  .controller('homeCtrl', function($ionicPlatform, $scope, PushService, FirebaseService) {
    console.log('homeCtrl');

    $scope.control = {};
    $scope.status = {};
    $scope.system = {};

    var fb_init = localStorage.getItem('firebase_init');
    if (fb_init == 'true') {

      $ionicPlatform.ready(function() {
        PushService.init();
      });

      FirebaseService.init();
      var isup = FirebaseService.up();
      if (FirebaseService.up() == true) {
        // wait for device ready (cordova) before initialize push service

        $scope.pushCtrl0Change = function() {
          firebase.database().ref("control/alarm").set($scope.control.alarm == true);
        };
        // $scope.doRefresh();
      }
      $scope.doRefresh = function() {
        console.log('doRefresh-HomeCtrl');
        if (FirebaseService.up() == true) {
          var current_date = new Date();
          firebase.database().ref("control/time").set(Math.floor(current_date.getTime() / 1000));

          var ref = firebase.database().ref("/");
          // Attach an asynchronous callback to read the data at our posts reference
          ref.on('value', function(snapshot) {
            var payload = snapshot.val();
            $scope.control = payload.control;
            $scope.status = payload.status;
            var date = new Date();
            date.setTime($scope.status.time * 1000);
            var current_date = new Date();
            var delta = (current_date.getTime() - date.getTime());
            if (delta > 1000 * 30) {
              $scope.system.status = false;
            } else {
              $scope.system.status = true;
            }
          }, function(errorObject) {
            console.log("firebase failed: " + errorObject.code);
          });
        }
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
