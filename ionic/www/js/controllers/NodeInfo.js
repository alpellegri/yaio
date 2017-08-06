angular.module('app.controllers.NodeInfo', [])

  .controller('NodeInfoCtrl', function($ionicPlatform, $scope, PushService, FirebaseService) {
    console.log('NodeInfoCtrl');

    var fb_init = localStorage.getItem('firebase_init');
    if (fb_init == 'true') {

      $scope.control = {};
      $scope.status = {};
      $scope.system = {};

      $scope.pushCtrl1Change = function() {
        var ref = firebase.database().ref("control");
        if ($scope.control.wol) {
          ref.update({
            wol: true
          });
        } else {
          ref.update({
            wol: false
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
        console.log('doRefresh-NodeInfoCtrl');
        var ref = firebase.database().ref("/");
        // Attach an asynchronous callback to read the data at our posts reference
        ref.on('value', function(snapshot) {
          var payload = snapshot.val();
          var current_date = new Date();
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

      var ref = firebase.database().ref("control/monitor");
      ref.set(true);

      $scope.doRefresh();
    } else {
      console.log('Firebase not initialized');
      alert('Firebase not initialized');
      $scope.$broadcast('scroll.refreshComplete');
    }
  })
