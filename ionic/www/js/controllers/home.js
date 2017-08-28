angular.module('app.controllers.home', [])

  .controller('homeCtrl', function($ionicPlatform, $scope, FirebaseService) {
    console.log('homeCtrl');

    $scope.control = {};
    $scope.status = {};
    $scope.system = {};
    $scope.loading = true;

    var fb_init = 'true'; // localStorage.getItem('firebase_init');
    if (fb_init == 'true') {
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
          if (($scope.control.time - $scope.status.time) < 10) {
            $scope.$broadcast('scroll.refreshComplete');
            $scope.loading = false;
          } else {
            setTimeout(function() {
              $scope.doRefresh();
            }, 500);
          }
        } else {
          setTimeout(function() {
            $scope.doRefresh();
          }, 500);
        }
      };
      $scope.doRefresh();
    } else {
      console.log('Firebase not initialized');
      alert('Firebase not initialized');
      $scope.$broadcast('scroll.refreshComplete');
    }
  })
