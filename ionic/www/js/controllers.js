angular.module('app.controllers', [])

.controller('homeCtrl', function($scope, serviceLog) {
  console.log('homeCtrl');

  $scope.pushCtrl0 = { checked: false };
  $scope.pushCtrl1 = { checked: false };
  $scope.pushCtrl2 = { checked: true };
  $scope.RadioNum = 0;
  $scope.RadioCode = [];
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

  $scope.HomeButton1 = function() {
    $scope.RadioCode.push($scope.RadioNum);
    $scope.RadioNum++;
    console.log('button\n' + $scope.RadioCode);
  };
  $scope.HomeButton2 = function() {
    var len = $scope.RadioCode.length;
    var ref = new Firebase("https://ikka.firebaseIO.com/");
    console.log('list\n');
    for (i=0;i<len;i++) {
      var sensor_ref = ref.child('sensor/' + i.toString());
      sensor_ref.set({
        name: "pir",
        action: "00",
        code: $scope.RadioCode[i]
      });
      console.log('[' + i + ']: ' + $scope.RadioCode[i]);
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
  $scope.Text = 'rx data goes here';
  $scope.StsTxt = 'Disconnected';
  $scope.SensorNum = 0;
  $scope.RadioNum = 0;
  $scope.RadioCode = [];

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
    console.log($scope.WSStatus);
    if ($scope.WSStatus == 'Close') {
      $scope.ComButton = 'Connect to Node';
    } else if ($scope.WSStatus == 'Open') {
      $scope.ComButton = 'Disconnect to Node';
    } else if ($scope.WSStatus == 'Error') {
      $scope.ComButton = '...';
    }
    $scope.$broadcast("scroll.infiniteScrollComplete");
  };

  $scope.SetupUpdateFirebase = function() {
    var len = $scope.RadioCode.length;
    var ref = new Firebase("https://ikka.firebaseIO.com/");
    console.log('list\n');
    for (i=0;i<len;i++) {
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
  $scope.data = {};

  // An elaborate, custom popup
  var myPopup = $ionicPopup.show({
    template: '<input type="password" ng-model="data.wifi">',
    title: 'Enter Wi-Fi Password',
    subTitle: 'Please use normal things',
    scope: $scope,
    buttons: [
      { text: 'Cancel' },
      {
        text: '<b>Save</b>',
        type: 'button-positive',
        onTap: function(e) {
          if (!$scope.data.wifi) {
            //don't allow the user to close unless he enters wifi password
            e.preventDefault();
          } else {
            return $scope.data.wifi;
          }
        }
      }
    ]
  });

  myPopup.then(function(res) {
    console.log('Tapped!', res);
  });

  $timeout(function() {
     myPopup.close(); //close the popup after 3 seconds for some reason
  }, 3000);
 };

 // A confirm dialog
 $scope.showConfirm = function(message) {
   var confirmPopup = $ionicPopup.confirm({
     title: 'Radio code ' + message + ' has found',
     template: 'Are you sure you want to save?'
   });

  confirmPopup.then(function(res) {
    if(res) {
      var obj = JSON.parse(message);
      console.log('RadioCode ' + obj.sensor);
      if (obj.sensor != null) {
        console.log('RadioCode OK');
        $scope.RadioCode.push(obj.sensor);
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

  $scope.doList = function() {
    console.log('doList');
    $scope.logs = serviceLog.getlog();
	$scope.$broadcast("scroll.infiniteScrollComplete");
  };

  $scope.doRefresh = function() {
    console.log('Refresh');
    $scope.logs = serviceLog.getlog();
	$scope.$broadcast("scroll.refreshComplete");
  };
  $scope.logs = {};
})
