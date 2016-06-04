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
      service.open_cb();
    };

    ws.onclose = function() {
      service.close_cb();
    };

    ws.onerror = function() {
      service.error_cb();
    }

    ws.onmessage = function(message) {
      console.log('>>>>' + message.data);
      service.message_cb(message.data);
    };

    service.ws = ws;
  }
 
  service.disconnect = function() {
    service.ws.close();
  }

  service.send = function(message) {
    service.ws.send(message);
  }
 
  service.subscribe = function(open_cb, close_cb, error_cb, message_cb) {
    service.open_cb = open_cb;
    service.close_cb = close_cb;
    service.error_cb = error_cb;
    service.message_cb = message_cb;
  }
 
  return service;
});
