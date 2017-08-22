angular.module('app.controllers.LogicalIOSetup', [])

  .controller('LogicalIOSetupCtrl', function($scope, $ionicPopup, $timeout) {
    console.log('LogicalIOSetupCtrl');

    var fb_init = localStorage.getItem('firebase_init');
    if (fb_init == 'true') {

      $scope.Lout = [];
      $scope.settings = {};

      // remove timer
      $scope.RemoveLout = function(i) {
        $scope.Lout.splice(i, 1);
      };

      $scope.SetupLIO = function() {
        var ref = firebase.database().ref("LIO/Lout");
        ref.remove();
        console.log('Lout');
        $scope.Lout.forEach(function(element) {
          console.log(element);
          ref.push().set({
            name: element.name,
            id: element.id
          });
        });

        var current_date = new Date();
        firebase.database().ref("control/time").set(Math.floor(current_date.getTime() / 1000));
        firebase.database().ref("control/radio_update").set(true);
      }

      $scope.ResetLIO = function() {
        console.log('LogicalIOSetupCtrl: ResetLIO');

        firebase.database().ref('LIO').remove();
        $scope.doRefresh();
      };

      // Triggered on a button click, or some other target
      $scope.showPopupLoutAdd = function() {
        var PopupTemplate =
          '<form class="list">' +
          '<h9 id="setup-heading5" style="text-align:left;">name</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="name" ng-model="settings._name"> </label>' +
          '<h9 id="setup-heading5" style="text-align:left;">LIO</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="lio" ng-model="settings._lio"> </label>' +
          '<h9 id="setup-heading5" style="text-align:left;">value</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="value" ng-model="settings._value"> </label>' +
          '</form>';

        // An elaborate, custom popup
        var myPopup = $ionicPopup.show({
          template: PopupTemplate,
          title: 'Lout Configuration',
          subTitle: '',
          scope: $scope,
          buttons: [{
            text: 'Cancel'
          }, {
            text: '<b>Save</b>',
            type: 'button-positive',
            onTap: function(e) {
              if (false) {
                // don't allow the user to close unless he enters wifi password
                e.preventDefault();
              } else {
                var _lio = {
                  name: $scope.settings._name,
                  id: 2 * parseInt($scope.settings._lio) + parseInt($scope.settings._value)
                };
                console.log(_lio);
                $scope.Lout.push(_lio);
                return $scope.settings;
              }
            }
          }]
        });

        myPopup.then(function(res) {
          console.log('Tapped!', $scope.settings);
        });

        // $timeout(function() {
        //   myPopup.close();
        // }, 90000);
      };

      // Triggered on a button click, or some other target
      $scope.showPopupLoutEdit = function(Lout) {
        $scope.settings._name = Lout.name;
        $scope.settings._lio = parseInt(Lout.id / 2);
        $scope.settings._value = parseInt(Lout.id % 2);
        var PopupTemplate =
          '<form class="list">' +
          '<h9 id="setup-heading5" style="text-align:left;">name</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="name" ng-model="settings._name"> </label>' +
          '<h9 id="setup-heading5" style="text-align:left;">LIO</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="lio" ng-model="settings._lio"> </label>' +
          '<h9 id="setup-heading5" style="text-align:left;">value</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="value" ng-model="settings._value"> </label>' +
          '</form>';

        // An elaborate, custom popup
        var myPopup = $ionicPopup.show({
          template: PopupTemplate,
          title: 'Lout Configuration',
          subTitle: '',
          scope: $scope,
          buttons: [{
            text: 'Cancel'
          }, {
            text: '<b>Save</b>',
            type: 'button-positive',
            onTap: function(e) {
              if (false) {
                // don't allow the user to close unless he enters wifi password
                e.preventDefault();
              } else {
                Lout.name = $scope.settings._name;
                Lout.id = 2 * parseInt($scope.settings._lio) + parseInt($scope.settings._value);
                console.log(Lout);
                return $scope.settings;
              }
            }
          }]
        });

        myPopup.then(function(res) {
          console.log('Tapped!', $scope.settings);
        });

        // $timeout(function() {
        //   myPopup.close();
        // }, 90000);
      };

      $scope.doRefresh = function() {
        console.log('doRefresh');
        var current_date = new Date();
        firebase.database().ref("control/time").set(Math.floor(current_date.getTime() / 1000));

        var ref = firebase.database().ref('LIO/Lout');
        var i = 0;
        $scope.Lout = [];
        ref.once('value', function(snapshot) {
          snapshot.forEach(function(childSnapshot) {
            // console.log(childSnapshot.val());
            $scope.Lout.push(childSnapshot.val());
            i++;
          });
        });

        // $scope.$broadcast("scroll.infiniteScrollComplete");
        $scope.$broadcast('scroll.refreshComplete');
      };

      $scope.doRefresh();
    }
  })
