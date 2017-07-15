angular.module('app.controllers.NodeSetup', [])

  .controller('NodeSetupCtrl', function($scope, WebSocketService, $ionicPopup, $timeout) {
    console.log('NodeSetupCtrl');

    var fb_init = localStorage.getItem('firebase_init');
    if (fb_init == 'true') {

      $scope.settings = {};
      var node_init = localStorage.getItem('firebase_init');
      if (node_init == 'true') {
        $scope.settings.ssid = localStorage.getItem('ssid');
        $scope.settings.password = localStorage.getItem('password');
        $scope.settings.firebase_url = localStorage.getItem('firebase_url');
        $scope.settings.firebase_secret = localStorage.getItem('firebase_secret');
        $scope.settings.firebase_server_key = localStorage.getItem('firebase_server_key');
      }

      $scope.message = {};
      $scope.WSStatus = 'Close';
      $scope.ComButton = 'Connect to Node';
      $scope.Text = '';
      $scope.NodeSettingMsg = '';
      $scope.StsTxt = 'Disconnected';

      $scope.settings.ComposeText = function() {
        $scope.settings.ssid = localStorage.getItem('ssid');
        $scope.settings.password = localStorage.getItem('password');
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
  })

  .controller('RadioCtrl', function($scope, $ionicPopup, $timeout) {
    console.log('RadioCtrl');

    var fb_init = localStorage.getItem('firebase_init');
    if (fb_init == 'true') {

      $scope.pushCtrl0 = {
        checked: false
      };

      $scope.InactiveRadioCodes = [];
      $scope.ActiveRadioCodes = [];

      // remove radio code
      $scope.RemoveInactiveRadioCode = function(i) {
        $scope.InactiveRadioCodes.splice(i, 1);
      };

      // move radio code to active
      $scope.ActivateRadioCode = function(i) {
        $scope.ActiveRadioCodes.push($scope.InactiveRadioCodes[i]);
        $scope.InactiveRadioCodes.splice(i, 1);
      };

      // remove radio code
      $scope.RemoveActiveRadioCode = function(i) {
        $scope.ActiveRadioCodes.splice(i, 1);
      };

      // move radio code to inactive
      $scope.DeactivateRadioCode = function(i) {
        $scope.InactiveRadioCodes.push($scope.ActiveRadioCodes[i]);
        $scope.ActiveRadioCodes.splice(i, 1);
      };

      $scope.SetupRadio = function() {
        var ref = firebase.database().ref("RadioCodes");
        ref.child('Active').remove();
        console.log('active');
        $scope.ActiveRadioCodes.forEach(function(element) {
          console.log(element.val());
          ref.child('Active').push().set(element.val());
        });
        ref.child('Inactive').remove();
        console.log('inactive');
        $scope.InactiveRadioCodes.forEach(function(element) {
          console.log(element.val());
          ref.child('Inactive').push().set(element.val());
        });
      }

      $scope.pushCtrl0Change = function() {
        var ref = firebase.database().ref("control");
        console.log('radio_learn control ' + $scope.pushCtrl0.checked);
        if ($scope.pushCtrl0.checked) {
          ref.update({
            radio_learn: true
          });
        } else {
          ref.update({
            radio_learn: false
          });
        }
      };

      $scope.doRefresh = function() {
        console.log('doRefresh');

        var ref_inactive = firebase.database().ref('RadioCodes/Inactive');
        var i = 0;
        $scope.InactiveRadioCodes = [];
        ref_inactive.once('value', function(snapshot) {
          snapshot.forEach(function(childSnapshot) {
            // console.log(childSnapshot.val());
            $scope.InactiveRadioCodes.push(childSnapshot);
            i++;
          });
        });

        var ref_active = firebase.database().ref('RadioCodes/Active');
        var i = 0;
        $scope.ActiveRadioCodes = [];
        ref_active.once('value', function(snapshot) {
          snapshot.forEach(function(childSnapshot) {
            // console.log(childSnapshot.val());
            $scope.ActiveRadioCodes.push(childSnapshot);
            i++;
          });
        });

        var ref = firebase.database().ref("control/radio_learn");
        // Attach an asynchronous callback to read the data at our posts reference
        ref.on('value', function(snapshot) {
          var payload = snapshot.val();

          if (payload == true) {
            $scope.pushCtrl0.checked = true;
          } else {
            $scope.pushCtrl0.checked = false;
          }
        }, function(errorObject) {
          console.log("firebase failed: " + errorObject.code);
        });

        // $scope.$broadcast("scroll.infiniteScrollComplete");
        $scope.$broadcast('scroll.refreshComplete');
      };

      $scope.doRefresh();
    }
  })

  .controller('loggerCtrl', function($scope) {
    console.log('loggerCtrl');
    $scope.logsText = "";

    $scope.doRefresh = function() {
      console.log('doRefresh');
      var ref = firebase.database().ref('logs/Reports').limitToLast(20);
      $scope.logsText = "";
      ref.once('value', function(snapshot) {
        snapshot.forEach(function(childSnapshot) {
          // console.log(childSnapshot.val());
          $scope.logsText += childSnapshot.val() + '\n';
        });
      });

      // $scope.$broadcast("scroll.infiniteScrollComplete");
      $scope.$broadcast("scroll.refreshComplete");
    };

    $scope.doRefresh();
  })
