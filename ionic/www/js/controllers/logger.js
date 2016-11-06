angular.module('app.controllers')

.controller('loggerCtrl', ['$scope', '$http', function($scope, serviceLog) {
  console.log('loggerCtrl');
  $scope.logsText = {};

  $scope.doRefresh = function() {
    console.log('doRefresh');
    $scope.logsText = serviceLog.getlog();
    // $scope.$broadcast("scroll.refreshComplete");
    $scope.$broadcast("scroll.infiniteScrollComplete");
  };
}]);
