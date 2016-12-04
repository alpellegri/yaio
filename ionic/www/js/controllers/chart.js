angular.module('app.controllers.chart', [])

.controller("chartCtrl", function($scope) {
  console.log('chartCtrl');

  $scope.JsonTH = {};
  $scope.JsonTH.labels = [];
  $scope.JsonTH.series = ['temperature', 'humidity'];
  $scope.JsonTH.data = [
    [],
    []
  ];
  $scope.JsonTH.onClick = function(points, evt) {
    console.log(points, evt);
  };
  $scope.JsonTH.datasetOverride = [{
    yAxisID: 'y-axis-1'
  }, {
    yAxisID: 'y-axis-2'
  }];
  $scope.JsonTH.options = {
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

  $scope.JsonT = {};
  $scope.JsonT.data = [
    []
  ];
  $scope.JsonH = {};
  $scope.JsonH.data = [
    []
  ];

  $scope.doRefresh = function() {
    console.log('doRefresh');

    var date = new Date();
    var curr = Math.round(2 * (date.getHours() + date.getMinutes() / 60));

    $scope.JsonTH.data[0] = [];
    $scope.JsonTH.data[1] = [];
    $scope.JsonTH.labels = [];
    $scope.JsonT.data[0] = [];
    $scope.JsonH.data[0] = [];
    // 2 days: 2 * (24 * 2) -> 96
    var ref = firebase.database().ref('logs/TH').limitToLast(96);
    ref.once('value', function(snapshot) {
      var i = curr - (snapshot.numChildren() - 96);
      snapshot.forEach(function(el) {
        $scope.JsonTH.data[0].push(el.val().t / 10);
        $scope.JsonTH.data[1].push(el.val().h / 10);
        if (i % 2 == 0) {
          var ii = (i / 2) % 24; // wrap hour: every one days
          $scope.JsonTH.labels.push(ii.toString());
        } else {
          $scope.JsonTH.labels.push("");
        }
        i++;
      });
      $scope.JsonT.data[0] = $scope.JsonTH.data[0];
      $scope.JsonH.data[0] = $scope.JsonTH.data[1];
    });

    // $scope.$broadcast("scroll.infiniteScrollComplete");
    $scope.$broadcast('scroll.refreshComplete');
  };

  $scope.doRefresh();
})
