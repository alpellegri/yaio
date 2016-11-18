angular.module('app.controllers.logger', [])

.controller('loggerCtrl', function($scope) {
  console.log('loggerCtrl');
  $scope.logsText = "";

  $scope.doRefresh = function() {
    console.log('doRefresh');
    var ref = firebase.database().ref('logs/Reports').limitToLast(20);
    $scope.logsText = "";
    ref.once('value', function(snapshot) {
      snapshot.forEach(function(childSnapshot) {
        // console.log(childSnapshot.val());
        $scope.logsText += childSnapshot.val() + '\n';
      });
    });

    // $scope.$broadcast("scroll.infiniteScrollComplete");
    $scope.$broadcast("scroll.refreshComplete");
  };

  $scope.doRefresh();
})
