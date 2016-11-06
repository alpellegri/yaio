angular.module('app.controllers')

.controller('homeCtrl', ['$scope', '$http', '$ionicPlatform', function($ionicPlatform, $scope, PushService, serviceLog) {
  console.log('homeCtrl');

  var fb_url = localStorage.getItem('firebase_url');
  if (fb_url != null) {
    $scope.pushCtrl0 = {
      checked: false
    };
    $scope.pushCtrl1 = {
      checked: false
    };
    $scope.pushCtrl2 = {
      checked: false
    };
    $scope.pushCtrl3 = {
      checked: false
    };
    $scope.status = {};

    // wait for device ready (cordova) before initialize push service
    $ionicPlatform.ready(function() {
      PushService.init();
    });

    $scope.pushCtrl0Change = function() {
      var ref = firebase.database().ref("control");
      serviceLog.putlog('alarm control ' + $scope.pushCtrl0.checked);
      if ($scope.pushCtrl0.checked) {
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
      serviceLog.putlog('led control ' + $scope.pushCtrl1.checked);
      if ($scope.pushCtrl1.checked) {
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
      serviceLog.putlog('reboot control ' + $scope.pushCtrl2.checked);
      if ($scope.pushCtrl2.checked) {
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
      serviceLog.putlog('monitor control ' + $scope.pushCtrl3.checked);
      if ($scope.pushCtrl3.checked) {
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
      serviceLog.putlog('refresh home');

      var ref = firebase.database().ref("/");
      // Attach an asynchronous callback to read the data at our posts reference
      ref.on('value', function(snapshot) {
        var payload = snapshot.val();

        if (payload.control.alarm == true) {
          $scope.pushCtrl0.checked = true;
        } else {
          $scope.pushCtrl0.checked = false;
        }

        if (payload.control.led == true) {
          $scope.pushCtrl1.checked = true;
        } else {
          $scope.pushCtrl1.checked = false;
        }

        if (payload.control.monitor == true) {
          $scope.pushCtrl3.checked = true;
        } else {
          $scope.pushCtrl3.checked = false;
        }

        if (payload.control.reboot == true) {
          $scope.pushCtrl2.checked = true;
        } else {
          $scope.pushCtrl2.checked = false;
        }

        $scope.status = payload.status;
      }, function(errorObject) {
        serviceLog.putlog("firebase failed: " + errorObject.code);
      });
      $scope.$broadcast('scroll.refreshComplete');
    };
  }
}]);
