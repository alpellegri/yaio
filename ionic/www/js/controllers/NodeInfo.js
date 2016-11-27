angular.module('app.controllers.NodeInfo', [])

.controller('NodeInfoCtrl', function($ionicPlatform, $scope, PushService, FirebaseService) {
  console.log('NodeInfoCtrl');

  var fb_init = localStorage.getItem('firebase_init');
  if (fb_init == 'true') {

    $scope.control = {};
    $scope.status = {};
    $scope.system = {};

    $scope.doRefresh = function() {
      console.log('doRefresh-HomeCtrl');
      var ref = firebase.database().ref("/");
      // Attach an asynchronous callback to read the data at our posts reference
      ref.on('value', function(snapshot) {
        var payload = snapshot.val();
        $scope.control = payload.control;
        $scope.status = payload.status;
        var date = new Date();
        date.setTime($scope.status.time * 1000);
        $scope.system.date = date.toString();
        var current_date = new Date();
        var delta = (current_date.getTime() - date.getTime());
        if (delta > 1000*10) {
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
