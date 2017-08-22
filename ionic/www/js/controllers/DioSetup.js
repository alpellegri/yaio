angular.module('app.controllers.DioSetup', [])

  .controller('DioSetupCtrl', function($scope, $ionicPopup, $timeout) {
    console.log('DioSetupCtrl');

    var fb_init = localStorage.getItem('firebase_init');
    if (fb_init == 'true') {

      $scope.Dout = [];
      $scope.settings = {};

      // remove timer
      $scope.RemoveDout = function(i) {
        $scope.Dout.splice(i, 1);
      };

      $scope.SetupDIO = function() {
        var ref = firebase.database().ref("DIO/Dout");
        ref.remove();
        console.log('Dout');
        $scope.Dout.forEach(function(element) {
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

      $scope.ResetDIO = function() {
        console.log('DioSetupCtrl: ResetDIO');

        firebase.database().ref('DIO').remove();
        $scope.doRefresh();
      };

      // Triggered on a button click, or some other target
      $scope.showPopupDoutAdd = function() {
        var PopupTemplate =
          '<form class="list">' +
          '<h9 id="setup-heading5" style="text-align:left;">name</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="name" ng-model="settings._name"> </label>' +
          '<h9 id="setup-heading5" style="text-align:left;">DIO</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="dio" ng-model="settings._dio"> </label>' +
          '<h9 id="setup-heading5" style="text-align:left;">value</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="value" ng-model="settings._value"> </label>' +
          '</form>';

        // An elaborate, custom popup
        var myPopup = $ionicPopup.show({
          template: PopupTemplate,
          title: 'Dout Configuration',
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
                var _dio = {
                  name: $scope.settings._name,
                  id: 2 * parseInt($scope.settings._dio) + parseInt($scope.settings._value)
                };
                console.log(_dio);
                $scope.Dout.push(_dio);
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
      $scope.showPopupDoutEdit = function(Dout) {
        $scope.settings._name = Dout.name;
        $scope.settings._dio = parseInt(Dout.id / 2);
        $scope.settings._value = parseInt(Dout.id % 2);
        var PopupTemplate =
          '<form class="list">' +
          '<h9 id="setup-heading5" style="text-align:left;">name</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="name" ng-model="settings._name"> </label>' +
          '<h9 id="setup-heading5" style="text-align:left;">DIO</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="dio" ng-model="settings._dio"> </label>' +
          '<h9 id="setup-heading5" style="text-align:left;">value</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="value" ng-model="settings._value"> </label>' +
          '</form>';

        // An elaborate, custom popup
        var myPopup = $ionicPopup.show({
          template: PopupTemplate,
          title: 'Dout Configuration',
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
                Dout.name = $scope.settings._name;
                Dout.id = 2 * parseInt($scope.settings._dio) + parseInt($scope.settings._value);
                console.log(Dout);
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

        var ref = firebase.database().ref('DIO/Dout');
        var i = 0;
        $scope.Dout = [];
        ref.once('value', function(snapshot) {
          snapshot.forEach(function(childSnapshot) {
            // console.log(childSnapshot.val());
            $scope.Dout.push(childSnapshot.val());
            i++;
          });
        });

        // $scope.$broadcast("scroll.infiniteScrollComplete");
        $scope.$broadcast('scroll.refreshComplete');
      };

      $scope.doRefresh();
    }
  })
