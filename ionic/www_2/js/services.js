angular.module('app.services', [])

.factory('BlankFactory', [function(){

}])

.factory('serviceLog', function() {
	var ids = 0;
	var logs = [];
	return {
		putlog: function(message) {
			// console.log(message);
			logs[ids++] = message;
			return;
		},
		getlog: function(){
			return logs;
		}
	}
})

.service('BlankService', [function(){

}]);
