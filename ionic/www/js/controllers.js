angular.module('app.controllers', [])

.controller('homeCtrl', function($scope, serviceLog) {
  console.log('homeCtrl');

  $scope.pushCtrl0Change = function() {
    serviceLog.putlog('LED ' + $scope.pushCtrl0.checked);
	if ($scope.pushCtrl0.checked) {
		messagesRef.update({data: 1});
	} else {
		messagesRef.update({data: 0});
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
		var data = payload.data;
		var ctrl = payload.ctrl.button;
		serviceLog.putlog('firebase: ' + "data " + data + " ctrl " + ctrl);
		if (data == 1) {
			$scope.pushCtrl0.checked = true;
		} else if (data == 0) {
			$scope.pushCtrl0.checked = false;
		} else {
		}
		if (ctrl == 1) {
			$scope.pushCtrl1.checked = true;
		} else if (ctrl == 0) {
			$scope.pushCtrl1.checked = false;
		} else {
		}
		$scope.$broadcast('scroll.refreshComplete');
	}, function (errorObject) {
		serviceLog.putlog("firebase failed: " + errorObject.code);
	});
  };

  $scope.pushCtrl0 = { checked: false };
  $scope.pushCtrl1 = { checked: false };
  $scope.pushCtrl2 = { checked: true };
})

.controller('setupCtrl', function($scope, WebSocketService, serviceLog) {
  console.log('setupCtrl');

  // $scope.messages = [];
  $scope.message = {};
  $scope.WSStatus = 'Close';
  $scope.settings = {};
  $scope.ComButton = 'Connect to Node';
  $scope.Text = 'rx data goes here';
  $scope.StsTxt = 'Disconnected';

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
