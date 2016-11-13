angular.module('app.controllers.chart', [])

.controller("chartCtrl", function($scope) {
  console.log('chartCtrl');

  $scope.myJson = {};
  $scope.myJson.labels = [];
  $scope.myJson.series = ['temperature', 'humidity'];
  $scope.myJson.data = [
    [],
    []
  ];
  $scope.myJson.onClick = function(points, evt) {
    console.log(points, evt);
  };
  $scope.myJson.datasetOverride = [{
    yAxisID: 'y-axis-1'
  }, {
    yAxisID: 'y-axis-2'
  }];
  $scope.myJson.options = {
    scales: {
      yAxes: [{
        id: 'y-axis-1',
        type: 'linear',
        display: true,
        position: 'left'
      }, {
        id: 'y-axis-2',
        type: 'linear',
        display: true,
        position: 'right'
      }]
    }
  };

  $scope.doRefresh = function() {
    console.log('doRefresh');

    $scope.myJson.data[0] = [];
    $scope.myJson.data[1] = [];
    $scope.myJson.labels = [];
    // 2 days: 2 * (24 * 4)
    var ref = firebase.database().ref('logs/TH').limitToLast(2 * 24 * 4);
    var i = 0;
    ref.once('value', function(snapshot) {
      snapshot.forEach(function(childSnapshot) {
        // console.log(childSnapshot.val());
        $scope.myJson.data[0].push(childSnapshot.val().t / 10);
        $scope.myJson.data[1].push(childSnapshot.val().h / 10);
        if (i % 4 == 0) {
          var ii = (i / 4) % 24; // wrap hour: every one days
          $scope.myJson.labels.push(ii.toString());
        } else {
          $scope.myJson.labels.push("");
        }
        i++;
      });
    });

    // $scope.$broadcast("scroll.infiniteScrollComplete");
    $scope.$broadcast('scroll.refreshComplete');
  };

  $scope.doRefresh();
})
