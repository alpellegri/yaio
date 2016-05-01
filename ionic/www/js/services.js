angular.module('app.services', [])

.factory('BlankFactory', [function(){

}])

.service('BlankService', [function(){

}])

.factory('serviceLog', function() {
	var ids = 0;
	var logs = [];
	return {
		putlog: function(message) {
			console.log(message);
			logs[ids++] = message;
			return;
		},
		getlog: function(){
			return logs;
		}
	}
})

.factory('WebSocketService', function() {
  var service = {};
 
  service.connect = function() {
    // if (service.ws) { return; }

    var wsUri = "ws://192.168.2.1:81/";
    var ws = new WebSocket(wsUri);

    ws.onopen = function() {
      service.callback('Open');
    };

    ws.onclose = function() {
      service.callback('Close');
    };

    ws.onerror = function() {
      service.callback('Error');
    }

    ws.onmessage = function(message) {
      service.callback(message.data);
    };

    service.ws = ws;
  }
 
  service.disconnect = function() {
    service.ws.close();
  }

  service.send = function(message) {
    service.ws.send(message);
  }
 
  service.subscribe = function(callback) {
    service.callback = callback;
  }
 
  return service;
});
