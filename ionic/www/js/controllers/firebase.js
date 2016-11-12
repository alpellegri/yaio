angular.module('app.controllers')

.controller('firebaseCtrl', ['$scope', '$http', function($scope, serviceLog, $ionicPopup, $timeout) {
  console.log('firebaseCtrl');

  $scope.settings = {};

  $scope.doRefresh = function() {
    console.log('doRefresh-firebase');
    $scope.$broadcast("scroll.infiniteScrollComplete");
  };

  $scope.InitFirebase = function() {
    var ref = firebase.database().ref("/");

    // init Firebase: control
    var control_ref = ref.child('control');
    control_ref.set({
      alarm: false,
      heap: false,
      led: false,
      monitor: false,
      radio_learn: false,
      reboot: false,
      scheduler: 10
    });
    // init Firebase: status
    var starus_ref = ref.child('status');
    starus_ref.set({
      alarm: false,
      bootcnt: 0,
      upcnt: 0,
      humidity: 0,
      temperature: 0,
      fire: false,
      flood: false,
      heap: 0
    });
  };

  $scope.ResetFirebase = function() {
    localStorage.removeItem('firebase_url');
    localStorage.removeItem('firebase_secret');
    localStorage.removeItem('firebase_server_key');
  }

  // Triggered on a button click, or some other target
  $scope.showPopup = function() {
    var PopupTemplate =
      '<form class="list">' +
      '<label class="item item-input"> <input type="text" placeholder="firebase url" name="firebase_url" ng-model="settings.firebase_url"> </label>' +
      '<label class="item item-input"> <input type="text" placeholder="firebase secret" name="secret" ng-model="settings.secret"> </label>' +
      '<label class="item item-input"> <input type="text" placeholder="firebase server key" name="server_key" ng-model="settings.server_key"> </label>' +
      '</form>';

    // An elaborate, custom popup
    var myPopup = $ionicPopup.show({
      template: PopupTemplate,
      title: 'Firebase setup',
      subTitle: '',
      scope: $scope,
      buttons: [{
        text: 'Cancel'
      }, {
        text: '<b>Save</b>',
        type: 'button-positive',
        onTap: function(e) {
          if (!$scope.settings.firebase_url || !$scope.settings.secret || !$scope.settings.server_key) {
            //don't allow the user to close unless he enters wifi password
            e.preventDefault();
          } else {
            // $scope.settings.ComposeText();
            localStorage.setItem('firebase_url', $scope.settings.firebase_url);
            localStorage.setItem('firebase_secret', $scope.settings.secret);
            localStorage.setItem('firebase_server_key', $scope.settings.server_key);
            return $scope.settings;
          }
        }
      }]
    });

    myPopup.then(function(res) {
      console.log('Tapped!', $scope.settings);
    });

    $timeout(function() {
      myPopup.close(); //close the popup after 9 seconds for some reason
    }, 90000);
  };

  // An alert dialog
  $scope.showAlert = function() {
    var alertPopup = $ionicPopup.alert({
      title: 'Don\'t eat that!',
      template: 'It might taste good'
    });

    alertPopup.then(function(res) {
      console.log('Thank you for not eating my delicious ice cream cone');
    });
  };
}]);
