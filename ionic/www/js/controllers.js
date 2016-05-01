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
  $scope.WSStatus = 'Disconnected';
  $scope.settings = {};
  $scope.ComButton = 'Connect to Node';
  $scope.Text = 'rx data goes here';

  WebSocketService.subscribe(function(message) {
    // $scope.messages.push(message);
    $scope.$apply();
    $scope.message = message;
    if (message == 'Connected') {
      $scope.WSStatus = message;
    } else if (message == 'Close') {
      $scope.WSStatus = 'Disconnected';
    }
  });

  $scope.SetupComCmd = function() {
    if ($scope.WSStatus == 'Disconnected') {
      serviceLog.putlog('ws connect');
      WebSocketService.connect();
    } else if ($scope.WSStatus = 'Connected') {
      serviceLog.putlog('ws disconnect');
	  WebSocketService.disconnect();
    } else {
      serviceLog.putlog('ws cmd not applicable');
    }
  };

  $scope.SetupComSend = function(settings) {
    if ($scope.WSStatus = 'Connected') {
      serviceLog.putlog('ws send');
      var payload = JSON.stringify(settings);
      console.log(settings);
      serviceLog.putlog(payload);
      WebSocketService.send(payload);          
    } else {
      serviceLog.putlog('ws send not applicable');
    }
  };

  $scope.doRefresh = function() {
    if ($scope.WSStatus == 'Disconnected') {
      $scope.ComButton = 'Connect to Node';
    } else if ($scope.WSStatus == 'Connected') {
      $scope.ComButton = 'Disconnect to Node';
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
