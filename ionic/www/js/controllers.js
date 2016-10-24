angular.module('app.controllers', [])

.controller('homeCtrl', function($ionicPlatform, $scope, PushService, serviceLog) {
  console.log('homeCtrl');

  var fb_url = localStorage.getItem('firebase_url');
  if (fb_url != null) {
    $scope.pushCtrl0 = {
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

    $scope.pushCtrl0Change2 = function() {
      var ref = firebase.database().ref("control");
      serviceLog.putlog('alarm control ' + $scope.pushCtrl0.checked);
      if ($scope.status.alarm == true) {
        ref.update({
          alarm: false
        });
      } else {
        ref.update({
          alarm: true
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
        var control_alarm = payload.control.alarm;
        if (control_alarm == true) {
          $scope.pushCtrl0.checked = true;
        } else {
          $scope.pushCtrl0.checked = false;
        }
        var control_monitor = payload.control.monitor;
        if (control_monitor == true) {
          $scope.pushCtrl3.checked = true;
        } else {
          $scope.pushCtrl3.checked = false;
        }
        var control_reboot = payload.control.reboot;
        if (control_reboot == true) {
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
})

.controller('setupCtrl', function($scope, WebSocketService, serviceLog, $ionicPopup, $timeout) {
  console.log('setupCtrl');

  var fb_url = localStorage.getItem('firebase_url');
  if (fb_url != null) {

    $scope.message = {};
    $scope.WSStatus = 'Close';
    $scope.settings = {};
    $scope.ComButton = 'Connect to Node';
    $scope.Text = '';
    $scope.NodeSettingMsg = '';
    $scope.StsTxt = 'Disconnected';
    $scope.SensorNum = 0;
    $scope.RadioNum = 0;
    $scope.RadioCode = [];
    $scope.RadioListText = '';

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

    $scope.SetupRadio = function() {
      var len = $scope.RadioCode.length;
      var ref = firebase.database().ref("/");

      // init Firebase: sensor
      for (i = 0; i < len; i++) {
        var sensor_ref = ref.child('sensor/' + i.toString());
        sensor_ref.set({
          name: "pir",
          action: "00",
          code: $scope.RadioCode[i]
        });
        console.log('[' + i + ']: ' + $scope.RadioCode[i]);
      }
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

    // A confirm dialog
    $scope.showConfirm = function(message) {
      var confirmPopup = $ionicPopup.confirm({
        title: 'Radio message ' + message + ' has found',
        template: 'Are you sure you want to save?'
      });

      confirmPopup.then(function(res) {
        if (res) {
          var obj = JSON.parse(message);
          console.log('RadioCode ' + obj.sensor);
          if (obj.sensor != null) {
            console.log('RadioCode OK');
            $scope.RadioCode.push(obj.sensor);
            $scope.RadioListText += obj.sensor + '\n';
          }
        } else {}
      });
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
    $scope.myJson.labels = [];
    var Ref = firebase.database().ref('logs/temperature').limitToLast(96);
    var i = 0;
    Ref.once('value', function(snapshot) {
      snapshot.forEach(function(childSnapshot) {
        $scope.myJson.data[0].push(childSnapshot.val());
        if (i % 4 == 0) {
          var ii = i / 4;
          $scope.myJson.labels.push(ii.toString());
        } else {
          $scope.myJson.labels.push("");
        }
        i++;
      });
    });

    $scope.myJson.data[1] = [];
    var Ref = firebase.database().ref('logs/humidity').limitToLast(96);
    var i = 0;
    Ref.once('value', function(snapshot) {
      snapshot.forEach(function(childSnapshot) {
        $scope.myJson.data[1].push(childSnapshot.val());
      });
    });

    // $scope.$broadcast("scroll.infiniteScrollComplete");
    $scope.$broadcast('scroll.refreshComplete');
  };
})

.controller('loggerCtrl', function($scope, serviceLog) {
  console.log('loggerCtrl');
  $scope.logsText = {};

  $scope.doRefresh = function() {
    console.log('doRefresh');
    $scope.logsText = serviceLog.getlog();
    // $scope.$broadcast("scroll.refreshComplete");
    $scope.$broadcast("scroll.infiniteScrollComplete");
  };
})

.controller('firebaseCtrl', function($scope, serviceLog, $ionicPopup, $timeout) {
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
      monitor: false,
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
})
