angular.module('app.controllers.History', [])

.controller('HistoryCtrl', function($scope) {
  console.log('HistoryCtrl');

  $scope.logsText = "";
  $scope.doRefresh = function() {
    console.log('doRefresh');
    var ref = firebase.database().ref('logs/Reports');
    $scope.logsText = "";
    ref.once('value', function(snapshot) {
      var date = new Date();

      snapshot.forEach(function(childSnapshot) {
        date.setTime(childSnapshot.val().time * 1000);
        $scope.logsText += date.toLocaleString() + '\t';
        $scope.logsText += childSnapshot.val().msg + '\n';
      });
    });

    // $scope.$broadcast("scroll.infiniteScrollComplete");
    $scope.$broadcast("scroll.refreshComplete");
  };

  $scope.doRefresh();
})
