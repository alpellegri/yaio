angular.module('app.controllers', [])

.controller('homeCtrl', function($ionicPlatform, $scope, PushService, FirebaseService) {
  console.log('homeCtrl');

  var fb_init = localStorage.getItem('firebase_init');
  console.log('firebase_init');
  console.log(fb_init);
  if (fb_init == 'true') {

    FirebaseService.init();

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
      console.log('alarm control ' + $scope.pushCtrl0.checked);
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
        console.log("firebase failed: " + errorObject.code);
      });
      $scope.$broadcast('scroll.refreshComplete');
    };

    $scope.doRefresh();
  }
})

.controller('NodeCtrl', function($scope, WebSocketService, $ionicPopup, $timeout) {
  console.log('NodeCtrl');

  var fb_init = localStorage.getItem('firebase_init');
  if (fb_init == 'true') {

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

.controller("chartCtrl", function($scope) {
  console.log('chartCtrl');

  $scope.myJson = {};
  $scope.myJson.labels = [];
  $scope.myJson.series = ['temperature', 'humidity'];
  $scope.myJson.data = [
    [],
    []
  ];
  $scope.myJson.onClick = function(points, evt) {
    console.log(points, evt);
  };
  $scope.myJson.datasetOverride = [{
    yAxisID: 'y-axis-1'
  }, {
    yAxisID: 'y-axis-2'
  }];
  $scope.myJson.options = {
    scales: {
      yAxes: [{
        id: 'y-axis-1',
        type: 'linear',
        display: true,
        position: 'left'
      }, {
        id: 'y-axis-2',
        type: 'linear',
        display: true,
        position: 'right'
      }]
    }
  };

  $scope.doRefresh = function() {
    console.log('doRefresh');

    $scope.myJson.data[0] = [];
    $scope.myJson.data[1] = [];
    $scope.myJson.labels = [];
    // 2 days: 2 * (24 * 4)
    var ref = firebase.database().ref('logs/TH').limitToLast(2 * 24 * 4);
    var i = 0;
    ref.once('value', function(snapshot) {
      snapshot.forEach(function(childSnapshot) {
        // console.log(childSnapshot.val());
        $scope.myJson.data[0].push(childSnapshot.val().t / 10);
        $scope.myJson.data[1].push(childSnapshot.val().h / 10);
        if (i % 4 == 0) {
          var ii = (i / 4) % 24; // wrap hour: every one days
          $scope.myJson.labels.push(ii.toString());
        } else {
          $scope.myJson.labels.push("");
        }
        i++;
      });
    });

    // $scope.$broadcast("scroll.infiniteScrollComplete");
    $scope.$broadcast('scroll.refreshComplete');
  };

  $scope.doRefresh();
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

.controller('firebaseCtrl', function($scope, FirebaseService, $ionicPopup, $timeout) {
  console.log('firebaseCtrl');

  $scope.settings = {};

  $scope.doRefresh = function() {
    console.log('doRefresh-firebase');
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
    localStorage.removeItem('firebase_init');
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
