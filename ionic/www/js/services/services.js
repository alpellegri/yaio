angular.module('app.services', [])

  .factory('BlankFactory', [function() {

  }])

  .service('BlankService', [function() {

  }])

  .factory('serviceLog', function() {
    var logsText = '';
    return {
      putlog: function(message) {
        console.log(message);
        logsText += message + '\n';
        return;
      },
      getlog: function() {
        return logsText;
      }
    }
  })
