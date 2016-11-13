angular.module('app.controllers.firebase', [])

.controller('firebaseCtrl', function($scope, FirebaseService, $ionicPopup, $timeout) {
  console.log('firebaseCtrl');

  $scope.settings = {};
  var fb_init = localStorage.getItem('firebase_init');
  if (fb_init == 'true') {
    $scope.settings.firebase_url = localStorage.getItem('firebase_url');
    $scope.settings.firebase_secret = localStorage.getItem('firebase_secret');
    $scope.settings.firebase_server_key = localStorage.getItem('firebase_server_key');
  }

  $scope.doRefresh = function() {
    console.log('doRefresh-firebaseCtrl');
    $scope.$broadcast('scroll.refreshComplete');
    $scope.$broadcast("scroll.infiniteScrollComplete");
  };

  $scope.InitFirebase = function() {
    console.log('firebaseCtrl: InitFirebase');
    FirebaseService.init();

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
    console.log('firebaseCtrl: ResetFirebase');
    localStorage.removeItem('firebase_init');
    localStorage.removeItem('firebase_url');
    localStorage.removeItem('firebase_secret');
    localStorage.removeItem('firebase_server_key');
    $scope.settings = {};
  }

  // Triggered on a button click, or some other target
  $scope.showPopup = function() {
    var PopupTemplate =
      '<form class="list">' +
      '<label class="item item-input"> <input type="text" placeholder="firebase_url" ng-model="settings.firebase_url"> </label>' +
      '<label class="item item-input"> <input type="text" placeholder="firebase_secret" ng-model="settings.firebase_secret"> </label>' +
      '<label class="item item-input"> <input type="text" placeholder="firebase_server_key" ng-model="settings.firebase_server_key"> </label>' +
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
          if (!$scope.settings.firebase_url || !$scope.settings.firebase_secret || !$scope.settings.firebase_server_key) {
            //don't allow the user to close unless he enters wifi password
            e.preventDefault();
          } else {
            // $scope.settings.ComposeText();
            localStorage.setItem('firebase_init', true);
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
})
