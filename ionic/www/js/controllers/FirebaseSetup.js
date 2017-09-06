angular.module('app.controllers.FirebaseSetup', [])

  .controller('FirebaseSetupCtrl', function($scope, FirebaseService, $ionicPopup, $timeout) {
    console.log('FirebaseSetupCtrl');

    $scope.settings = {};
    var fb_user_init = localStorage.getItem('firebase_user_init');
    if (fb_user_init == 'true') {
      $scope.settings.firebase_username = localStorage.getItem('firebase_username');
      $scope.settings.firebase_password = localStorage.getItem('firebase_password');
    }

    $scope.doRefresh = function() {
      console.log('doRefresh-firebaseCtrl');
      $scope.$broadcast('scroll.refreshComplete');
      $scope.$broadcast("scroll.infiniteScrollComplete");
    };

    $scope.InitFirebase = function() {
      console.log('firebaseCtrl: InitFirebase Database');

      // FirebaseService.init();

      var ref = firebase.database().ref("/");

      ref.child('FCM_Registration_IDs').remove();
      ref.child('RadioCodes').remove();
      ref.child('startup').remove();
      ref.child('status').remove();
      ref.child('control').remove();
      ref.child('logs').remove();

      // init Firebase: startup
      var startup_ref = ref.child('startup');
      startup_ref.set({
        bootcnt: 0,
        time: 0,
      });

      // init Firebase: control
      var control_ref = ref.child('control');
      control_ref.set({
        alarm: false,
        radio_learn: false,
        radio_update: false,
        reboot: false,
        time: 0
      });

      // init Firebase: status
      var starus_ref = ref.child('status');
      starus_ref.set({
        alarm: false,
        monitor: false,
        heap: 0,
        humidity: 0,
        temperature: 0,
        time: 0
      });
    };

    $scope.ResetFirebase = function() {
      console.log('firebaseCtrl: ResetFirebase');
      localStorage.removeItem('firebase_user_init');
      localStorage.removeItem('firebase_username');
      localStorage.removeItem('firebase_password');
      $scope.settings = {};
    }

    // Triggered on a button click, or some other target
    $scope.showPopupLogin = function() {
      var PopupTemplate =
        '<form class="list">' +
        '<h9 id="setup-heading5" style="text-align:left;">username</h9>' +
        '<label class="item item-input"> <input type="text" placeholder="firebase_username" ng-model="settings.firebase_username"> </label>' +
        '<h9 id="setup-heading5" style="text-align:left;">password</h9>' +
        '<label class="item item-input"> <input type="text" placeholder="firebase_password" ng-model="settings.firebase_password"> </label>' +
        '</form>';

      // An elaborate, custom popup
      var myPopup = $ionicPopup.show({
        template: PopupTemplate,
        title: 'Firebase Login',
        subTitle: '',
        scope: $scope,
        buttons: [{
          text: 'Cancel'
        }, {
          text: '<b>Save</b>',
          type: 'button-positive',
          onTap: function(e) {
            if (!$scope.settings.firebase_username || !$scope.settings.firebase_password) {
              // don't allow the user to close unless he enters wifi password
              e.preventDefault();
            } else {
              localStorage.setItem('firebase_user_init', true);
              localStorage.setItem('firebase_username', $scope.settings.firebase_username);
              localStorage.setItem('firebase_password', $scope.settings.firebase_password);
              return $scope.settings;
            }
          }
        }]
      });

      myPopup.then(function(res) {
        console.log('Tapped!', $scope.settings);
      });

      // $timeout(function() {
      //   myPopup.close();
      // }, 90000);
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
