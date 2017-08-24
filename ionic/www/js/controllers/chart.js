angular.module('app.controllers.chart', [])

  .controller("chartCtrl", function($scope) {
    console.log('chartCtrl');

    $scope.JsonH = {};
    $scope.JsonH.data = [
      []
    ];

    $scope.JsonT = {};
    $scope.JsonT.data = [];
    // The angular-chart directive will use this as the label
    $scope.JsonT.series = ['Scatter Dataset'];

    $scope.JsonT.options = {
      scales: {
        xAxes: [{
          type: "time",
          unit: 'day',
          unitStepSize: 1,
          display: true,
          time: {
            displayFormats: {
              'day': 'DD MMM'
            }
          }
        }],
      },
      elements: {
        point: {
          radius: 0,
        }
      }
    }

    $scope.JsonH = {};
    $scope.JsonH.data = [];
    // The angular-chart directive will use this as the label
    $scope.JsonH.series = ['Scatter Dataset'];

    $scope.JsonH.options = {
      scales: {
        xAxes: [{
          type: "time",
          unit: 'day',
          unitStepSize: 1,
          display: true,
          time: {
            displayFormats: {
              'day': 'DD MMM'
            }
          }
        }],
      },
      elements: {
        point: {
          radius: 0,
        }
      }
    }

    $scope.ClearChart = function() {
      console.log('chartCtrl: ClearChart');

      firebase.database().ref('logs/TH').remove();
      $scope.doRefresh();
    };

    $scope.doRefresh = function() {
      console.log('doRefresh');

      $scope.JsonT.data = [];
      $scope.JsonH.data = [];
      // 7 days: 7 * (24 * 2) -> 96
      var steps = 7 * (24 * 2);
      var ref = firebase.database().ref('logs/TH').limitToLast(steps);
      ref.once('value', function(snapshot) {
        snapshot.forEach(function(el) {
          $scope.JsonT.data.push({
            x: el.val().time * 1000,
            y: el.val().t / 10
          });
          $scope.JsonH.data.push({
            x: el.val().time * 1000,
            y: el.val().h / 10
          });
        });
      });

      // $scope.$broadcast("scroll.infiniteScrollComplete");
      $scope.$broadcast('scroll.refreshComplete');
    };

    $scope.doRefresh();
  })
