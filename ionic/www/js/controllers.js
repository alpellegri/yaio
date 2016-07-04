angular.module('app.controllers', [])

.controller('homeCtrl', function($scope, serviceLog) {
  console.log('homeCtrl');

  $scope.pushCtrl0 = { checked: false };
  $scope.pushCtrl1 = { checked: false };
  $scope.pushCtrl2 = { checked: true };
  $scope.status = {};

  $scope.pushCtrl0Change = function() {
    var ref = new Firebase("https://ikka.firebaseIO.com/control");
    serviceLog.putlog('LED ' + $scope.pushCtrl0.checked);
	if ($scope.pushCtrl0.checked) {
      ref.update({alarm: true});
	} else {
      ref.update({alarm: false});
	}
  };

  $scope.pushCtrl1Change = function() {
    serviceLog.putlog('CTRL1 ' + $scope.pushCtrl1.checked);
	if ($scope.pushCtrl1.checked) {

	} else {

	}
  };

  $scope.pushCtrl2Change = function() {
    serviceLog.putlog('CTRL2 ' + $scope.pushCtrl2.checked);
	if ($scope.pushCtrl2.checked) {

	} else {

	}
  };

  $scope.doRefresh = function() {
    serviceLog.putlog('refresh home');
	var ref = new Firebase("https://ikka.firebaseIO.com/");
	// Attach an asynchronous callback to read the data at our posts reference
	ref.on("value", function(snapshot) {
		var payload = snapshot.val();
		var control_alarm = payload.control.alarm;
		if (control_alarm == 1) {
			$scope.pushCtrl0.checked = true;
		} else if (control_alarm == 0) {
			$scope.pushCtrl0.checked = false;
		} else {
		}
//		if (ctrl == 1) {
//			$scope.pushCtrl1.checked = true;
//		} else if (ctrl == 0) {
//			$scope.pushCtrl1.checked = false;
//		} else {
//		}
        $scope.status = payload.status;
        
		$scope.$broadcast('scroll.refreshComplete');
	}, function (errorObject) {
		serviceLog.putlog("firebase failed: " + errorObject.code);
	});
  };
})

.controller('setupCtrl', function($scope, WebSocketService, serviceLog, $ionicPopup, $timeout) {
  console.log('setupCtrl');

  $scope.message = {};
  $scope.WSStatus = 'Close';
  $scope.settings = {};
  $scope.ComButton = 'Connect to Node';
  $scope.Text = '';
  $scope.StsTxt = 'Disconnected';
  $scope.SensorNum = 0;
  $scope.RadioNum = 0;
  $scope.RadioCode = [];
  $scope.RadioListText = '';

  $scope.settings.ComposeText = function() {
    $scope.settings.text =
      'Node WiFi SSID: ' + $scope.settings.ssid + '\n' +
      'Node WiFi PASSWORD: ' + $scope.settings.password + '\n' +
      'Firebase URL: ' + $scope.settings.password + '\n' +
      'Firebase Secret: ' + $scope.settings.password + '\n';
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

  $scope.SetupInitFirebase = function() {
    var len = $scope.RadioCode.length;
    var ref = new Firebase("https://ikka.firebaseIO.com/");

    // init Firebase: sensor
    for (i=0;i<len;i++) {
      var sensor_ref = ref.child('sensor/' + i.toString());
      sensor_ref.set({
        name: "pir",
        action: "00",
        code: $scope.RadioCode[i]
      });
      console.log('[' + i + ']: ' + $scope.RadioCode[i]);
    }
    // init Firebase: control
    var control_ref = ref.child('control');
    control_ref.set({
      reboot: false,
      alarm: false,
      heap: false,
      scheduler: 10
    });
    // init Firebase: status
    var starus_ref = ref.child('status');
    starus_ref.set({
      alarm: false,
      bootcnt: 0,
      upcnt: 0,
      umidity: 0,
      temperature: 0,
      fire: false,
      flood: false
    });
  };

  // Triggered on a button click, or some other target
  $scope.showPopup = function() {

  var PopupTemplate =
    '<form class="list">' +
    '<label class="item item-input"> <input type="text" placeholder="access point ssid" name="ssid" ng-model="settings.ssid"></label>' +
    '<label class="item item-input"> <input type="text" placeholder="access point password" name="password" ng-model="settings.password"> </label>' +
    '<label class="item item-input"> <input type="text" placeholder="firebase url" name="firebase" ng-model="settings.firebase"> </label>' +
    '<label class="item item-input"> <input type="text" placeholder="firebase secret" name="secret" ng-model="settings.secret"> </label>' +
    '</form>';

  // An elaborate, custom popup
  var myPopup = $ionicPopup.show({
    template: PopupTemplate,
    title: 'Enter Wi-Fi Password',
    subTitle: 'make sure your device is connected to Node WiFi AP',
    scope: $scope,
    buttons: [
      { text: 'Cancel' },
      {
        text: '<b>Save</b>',
        type: 'button-positive',
        onTap: function(e) {
          if (!$scope.settings.ssid || !$scope.settings.password || !$scope.settings.firebase || !$scope.settings.secret) {
            //don't allow the user to close unless he enters wifi password
            e.preventDefault();
          } else {
            $scope.settings.ComposeText();
            return $scope.settings;
          }
        }
      }
    ]
  });

  myPopup.then(function(res) {
    console.log('Tapped!', $scope.settings);
  });

  $timeout(function() {
     myPopup.close(); //close the popup after 3 seconds for some reason
  }, 30000);
 };

 // A confirm dialog
 $scope.showConfirm = function(message) {
   var confirmPopup = $ionicPopup.confirm({
     title: 'Radio message ' + message + ' has found',
     template: 'Are you sure you want to save?'
   });

  confirmPopup.then(function(res) {
    if(res) {
      var obj = JSON.parse(message);
      console.log('RadioCode ' + obj.sensor);
      if (obj.sensor != null) {
        console.log('RadioCode OK');
        $scope.RadioCode.push(obj.sensor);
        $scope.RadioListText += obj.sensor + '\n';
      }
    } else {
    }
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
