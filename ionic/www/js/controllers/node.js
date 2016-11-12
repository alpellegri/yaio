angular.module('app.controllers')

.controller('NodeCtrl', ['$scope', '$http', function($scope, WebSocketService, serviceLog, $ionicPopup, $timeout) {
  console.log('NodeCtrl');

  var fb_url = localStorage.getItem('firebase_url');
  if (fb_url != null) {

    $scope.message = {};
    $scope.WSStatus = 'Close';
    $scope.settings = {};
    $scope.ComButton = 'Connect to Node';
    $scope.Text = '';
    $scope.NodeSettingMsg = '';
    $scope.StsTxt = 'Disconnected';

    $scope.settings.ComposeText = function() {
      $scope.settings.firebase_url = localStorage.getItem('firebase_url');
      $scope.settings.secret = localStorage.getItem('firebase_secret');
      $scope.settings.server_key = localStorage.getItem('firebase_server_key');
      $scope.NodeSettings =
        'Node WiFi SSID: ' + $scope.settings.ssid + '\n' +
        'Node WiFi PASSWORD: ' + $scope.settings.password + '\n' +
        'Firebase URL: ' + $scope.settings.firebase_url + '\n' +
        'Firebase Secret: ' + $scope.settings.secret + '\n' +
        'Firebase Server Key: ' + $scope.settings.server_key + '\n';
    }

    WebSocketService.subscribe(
      // open
      function() {
        $scope.$apply();
        $scope.message = 'Open';
        $scope.WSStatus = 'Open';
        $scope.StsTxt = 'Connected';
        serviceLog.putlog('ws status: ' + $scope.WSStatus);
        $scope.Text = $scope.message;
      },
      // close
      function() {
        $scope.$apply();
        $scope.message = 'Close';
        $scope.WSStatus = 'Close';
        $scope.StsTxt = 'Disconnected';
        serviceLog.putlog('ws status: ' + $scope.WSStatus);
        $scope.Text = $scope.message;
      },
      // error
      function() {
        $scope.$apply();
        $scope.message = 'Error';
        $scope.WSStatus = 'Error';
        $scope.StsTxt = 'Error';
        serviceLog.putlog('ws status: ' + $scope.WSStatus);
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
        serviceLog.putlog('ws connect');
        $scope.StsTxt = 'Connecting...';
        WebSocketService.connect();
      } else if ($scope.WSStatus = 'Open') {
        serviceLog.putlog('ws disconnect');
        $scope.StsTxt = 'Disconnecting...';
        WebSocketService.disconnect();
      } else {
        serviceLog.putlog('ws cmd not applicable');
      }
    };

    $scope.SetupComSend = function(settings) {
      if ($scope.WSStatus == 'Open') {
        serviceLog.putlog('ws send');
        var payload = JSON.stringify(settings);
        // console.log(settings);
        serviceLog.putlog(payload);
        WebSocketService.send(payload);
      } else {
        serviceLog.putlog('ws send not applicable');
      }
    };

    $scope.doRefresh = function() {
      console.log('doRefresh');
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
        '<label class="item item-input"> <input type="text" placeholder="access point ssid" name="ssid" ng-model="settings.ssid"></label>' +
        '<label class="item item-input"> <input type="text" placeholder="access point password" name="password" ng-model="settings.password"> </label>' +
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
              $scope.settings.ComposeText();
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
}]);
