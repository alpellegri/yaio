angular.module('app.controllers.NodeInfo', [])

  .controller('NodeInfoCtrl', function($ionicPlatform, $scope, PushService, FirebaseService) {
    console.log('NodeInfoCtrl');

    var fb_init = 'true'; // localStorage.getItem('firebase_init');
    if (fb_init == 'true') {

      $scope.control = {};
      $scope.status = {};
      $scope.system = {};

      $scope.pushCtrl1Change = function() {
        firebase.database().ref("control/wol").set($scope.control.wol == true);
      };

      $scope.pushCtrl2Change = function() {
        firebase.database().ref("control/reboot").set($scope.control.reboot == true);
      };

      $scope.doRefresh = function() {
        console.log('doRefresh-NodeInfoCtrl');
        var current_date = new Date();
        firebase.database().ref("control/time").set(Math.floor(current_date.getTime() / 1000));

        var ref = firebase.database().ref("/");
        // Attach an asynchronous callback to read the data at our posts reference
        ref.on('value', function(snapshot) {
          var payload = snapshot.val();
          var date = new Date();
          // $scope.system.date = date.toString();
          $scope.startup = payload.startup;
          date.setTime($scope.startup.time * 1000);
          $scope.StartupTime = date.toLocaleString();
          var delta = (current_date.getTime() - date.getTime());
          $scope.system.uptime = delta;
          $scope.control = payload.control;
          $scope.status = payload.status;
          date.setTime($scope.status.time * 1000);
          $scope.HeartTime = date.toLocaleString();
          delta = (current_date.getTime() - date.getTime());
          if (delta > 1000 * 30) {
            $scope.system.status = false;
          } else {
            $scope.system.status = true;
          }
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
