angular.module('app.controllers.TimerSetup', [])

  .controller('TimerSetupCtrl', function($scope, $ionicPopup, $timeout) {
    console.log('TimerSetupCtrl');

    var fb_init = localStorage.getItem('firebase_init');
    if (fb_init == 'true') {

      $scope.Timers = [];
      $scope.settings = {};
      $scope.ActiveRadioCodesTx = [];
      $scope.ActiveTable = [];
      $scope.Dout = [];
      $scope.Types = [{
          name: "dio",
          type: 1
        },
        {
          name: "rf",
          type: 2
        },
      ];

      // remove timer
      $scope.RemoveTimer = function(i) {
        $scope.Timers.splice(i, 1);
      };

      $scope.SetupTimers = function() {
        var ref = firebase.database().ref("Timers");
        ref.remove();
        console.log('Timers');
        $scope.Timers.forEach(function(element) {
          console.log(element);
          ref.push().set({
            name: element.name,
            hour: element.hour,
            minute: element.minute,
            type: element.type,
            action: element.action
          });
        });
      }

      $scope.UpdateType = function(Timer, type) {
        console.log('UpdateType');
        console.log(type);
        Timer.type = parseInt(type);
        if (type == 1) {
          $scope.ActiveTable = $scope.Dout;
        } else if (type == 2) {
          $scope.ActiveTable = $scope.ActiveRadioCodesTx;
        } else {}
      };

      $scope.UpdateAction = function(Timer, action) {
        // console.log(action);
        Timer.action = parseInt(action);
      };

      // Triggered on a button click, or some other target
      $scope.showPopupTimerAdd = function() {
        var PopupTemplate =
          '<form class="list">' +
          '<h9 id="setup-heading5" style="text-align:left;">name</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="name" ng-model="settings._name"> </label>' +
          '<h9 id="setup-heading5" style="text-align:left;">hour</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="hour" ng-model="settings._hour"> </label>' +
          '<h9 id="setup-heading5" style="text-align:left;">minute</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="minute" ng-model="settings._minute"> </label>' +
          '</form>';

        // An elaborate, custom popup
        var myPopup = $ionicPopup.show({
          template: PopupTemplate,
          title: 'Timer Configuration',
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
                date = new Date();
                var offset = date.getTimezoneOffset()/60;
                var _timer = {
                  name: $scope.settings._name,
                  hour: ((($scope.settings._hour)+offset+24)%24),
                  minute: $scope.settings._minute,
                  type: 0,
                  action: 0
                };
                // console.log(_timer);
                $scope.Timers.push(_timer);
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
      $scope.showPopupTimerEdit = function(Timer) {
        $scope.settings._name = Timer.name;
        $scope.settings._hour = Timer.hour;
        $scope.settings._minute = Timer.minute;
        var PopupTemplate =
          '<form class="list">' +
          '<h9 id="setup-heading5" style="text-align:left;">name</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="name" ng-model="settings._name"> </label>' +
          '<h9 id="setup-heading5" style="text-align:left;">hour</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="hour" ng-model="settings._hour"> </label>' +
          '<h9 id="setup-heading5" style="text-align:left;">minute</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="minute" ng-model="settings._minute"> </label>' +
          '</form>';

        // An elaborate, custom popup
        var myPopup = $ionicPopup.show({
          template: PopupTemplate,
          title: 'Timer Configuration',
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
                date = new Date();
                var offset = date.getTimezoneOffset()/60;
                Timer.name = $scope.settings._name;
                Timer.hour = ((($scope.settings._hour)+offset+24)%24);
                Timer.minute = $scope.settings._minute;
                Timer.action = 0
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

        $scope.Timers = [];
        var ref = firebase.database().ref('Timers');
        var i = 0;
        ref.once('value', function(snapshot) {
          snapshot.forEach(function(childSnapshot) {
            // console.log(childSnapshot.val());
            $scope.Timers.push(childSnapshot.val());
            i++;
          });
        });

        var ref = firebase.database().ref('RadioCodes/ActiveTx');
        var i = 0;
        $scope.ActiveRadioCodesTx = [];
        ref.once('value', function(snapshot) {
          snapshot.forEach(function(childSnapshot) {
            // console.log(childSnapshot.val());
            $scope.ActiveRadioCodesTx.push(childSnapshot.val());
            i++;
          });
        });

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
