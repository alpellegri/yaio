angular.module('app.controllers.NodeSetup', [])

  .controller('NodeSetupCtrl', function($scope, FirebaseService, WebSocketService, $ionicPopup, $timeout) {
    console.log('NodeSetupCtrl');

    var fb_init = localStorage.getItem('firebase_init');
    if (fb_init == 'true') {

      $scope.settings = {};
      var node_init = localStorage.getItem('firebase_init');
      if (node_init == 'true') {
        $scope.settings.ssid = localStorage.getItem('ssid');
        $scope.settings.password = localStorage.getItem('password');
        $scope.settings.firebase_url = FirebaseService.Getfirebase_url();
        $scope.settings.storage_bucket = FirebaseService.Getstorage_bucket();
        $scope.settings.firebase_secret = localStorage.getItem('firebase_secret');
        $scope.settings.firebase_server_key = localStorage.getItem('firebase_server_key');
      }

      $scope.message = {};
      $scope.WSStatus = 'Close';
      $scope.ComButton = 'Connect to Node';
      $scope.Text = '';
      $scope.NodeSettingMsg = '';
      $scope.StsTxt = 'Disconnected';

      WebSocketService.subscribe(
        // open
        function() {
          $scope.$apply();
          $scope.message = 'Open';
          $scope.WSStatus = 'Open';
          $scope.StsTxt = 'Connected';
          console.log('ws status: ' + $scope.WSStatus);
          $scope.Text = $scope.message;
        },
        // close
        function() {
          $scope.$apply();
          $scope.message = 'Close';
          $scope.WSStatus = 'Close';
          $scope.StsTxt = 'Disconnected';
          console.log('ws status: ' + $scope.WSStatus);
          $scope.Text = $scope.message;
        },
        // error
        function() {
          $scope.$apply();
          $scope.message = 'Error';
          $scope.WSStatus = 'Error';
          $scope.StsTxt = 'Error';
          console.log('ws status: ' + $scope.WSStatus);
          $scope.Text = $scope.message;
        },
        // message
        function(message) {
          $scope.$apply();
          $scope.message = message;
          $scope.Text = message;
          // check if data is a sensor
          $scope.showConfirm(message);
        }
      );

      $scope.SetupComCmd = function() {
        if ($scope.WSStatus == 'Close') {
          console.log('ws connect');
          $scope.StsTxt = 'Connecting...';
          WebSocketService.connect();
        } else if ($scope.WSStatus = 'Open') {
          console.log('ws disconnect');
          $scope.StsTxt = 'Disconnecting...';
          WebSocketService.disconnect();
        } else {
          console.log('ws cmd not applicable');
        }
      };

      $scope.SetupComSend = function(settings) {
        if ($scope.WSStatus == 'Open') {
          console.log('ws send');
          var payload = JSON.stringify(settings);
          // console.log(settings);
          console.log(payload);
          WebSocketService.send(payload);
        } else {
          console.log('ws send not applicable');
        }
      };

      $scope.doRefresh = function() {
        console.log('doRefresh-NodeCtrl');
        if ($scope.WSStatus == 'Close') {
          $scope.ComButton = 'Connect to Node';
        } else if ($scope.WSStatus == 'Open') {
          $scope.ComButton = 'Disconnect to Node';
        } else if ($scope.WSStatus == 'Error') {
          $scope.ComButton = '...';
        }
        $scope.$broadcast("scroll.infiniteScrollComplete");
      };

      // Triggered on a button click, or some other target
      $scope.showPopup = function() {

        var PopupTemplate =
          '<form class="list">' +
          '<label class="item item-input"> <input type="text" placeholder="access point ssid" ng-model="settings.ssid"></label>' +
          '<label class="item item-input"> <input type="text" placeholder="access point password" ng-model="settings.password"> </label>' +
          '<label class="item item-input"> <input type="text" placeholder="firebase secret" ng-model="settings.firebase_secret"> </label>' +
          '<label class="item item-input"> <input type="text" placeholder="firebase cloud server key" ng-model="settings.firebase_server_key"> </label>' +
          '</form>';

        // An elaborate, custom popup
        var myPopup = $ionicPopup.show({
          template: PopupTemplate,
          title: 'Enter Access Point SSID and password',
          subTitle: 'make sure your device is connected to Node WiFi AP',
          scope: $scope,
          buttons: [{
            text: 'Cancel'
          }, {
            text: '<b>Save</b>',
            type: 'button-positive',
            onTap: function(e) {
              if (!$scope.settings.ssid || !$scope.settings.password) {
                //don't allow the user to close unless he enters wifi password
                e.preventDefault();
              } else {
                localStorage.setItem('node_init', true);
                localStorage.setItem('ssid', $scope.settings.ssid);
                localStorage.setItem('password', $scope.settings.password);
                localStorage.setItem('firebase_secret', $scope.settings.firebase_secret);
                localStorage.setItem('firebase_server_key', $scope.settings.firebase_server_key);
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
    }
  })
