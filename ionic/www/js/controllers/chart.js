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
    var curr = Math.round(4*(date.getHours() + date.getMinutes()/60));

    $scope.myJson.data[0] = [];
    $scope.myJson.data[1] = [];
    $scope.myJson.labels = [];
    $scope.JsonT.data[0] = [];
    $scope.JsonH.data[0] = [];
    // 2 days: 2 * (24 * 4) -> 192
    var ref = firebase.database().ref('logs/TH').limitToLast(192);
    ref.once('value', function(snapshot) {
      var i = curr - (snapshot.numChildren()-192);
      snapshot.forEach(function(el) {
        $scope.myJson.data[0].push(el.val().t / 10);
        $scope.myJson.data[1].push(el.val().h / 10);
        $scope.JsonT.data[0].push(el.val().t / 10);
        $scope.JsonH.data[0].push(el.val().h / 10);
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
