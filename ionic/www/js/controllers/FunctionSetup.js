angular.module('app.controllers.FunctionSetup', [])

  .controller('FunctionSetupCtrl', function($scope, $ionicPopup, $timeout) {
    console.log('FunctionSetupCtrl');

    var fb_init = localStorage.getItem('firebase_init');
    if (fb_init == 'true') {

      $scope.pushCtrl0 = {
        checked: false
      };

      $scope.settings = {};
      $scope.Functions = [];
      $scope.ActiveTable = [];
      $scope.ActiveTable_d = [];
      $scope.Dout = [];
      $scope.Lout = [];
      $scope.Types = [{
          name: "Empty",
          type: 0
        }, {
          name: "Digital IO",
          type: 1
        },
        {
          name: "Radio IO",
          type: 2
        },
        {
          name: "Logical IO",
          type: 3
        },
      ];

      $scope.Delays = [{
          name: "0 sec",
          time: 0
        },
        {
          name: "1 sec",
          time: 1
        },
        {
          name: "2 sec",
          time: 2
        },
        {
          name: "5 sec",
          time: 5
        },
        {
          name: "15 sec",
          time: 15
        },
        {
          name: "30 sec",
          time: 30
        },
        {
          name: "1 min",
          time: 1 * 60
        },
        {
          name: "2 min",
          time: 2 * 60
        },
        {
          name: "5 min",
          time: 5 * 60
        },
        {
          name: "15 min",
          time: 15 * 60
        },
      ];

      // remove radio code
      $scope.RemoveFunction = function(data, i) {
        data.splice(i, 1);
      };

      $scope.SetupFunctions = function() {
        console.log('FunctionSetupCtrl: SetupFunctions');
        var ref = firebase.database().ref("Functions");
        ref.remove();
        $scope.Functions.forEach(function(element) {
          console.log('element');
          console.log(element);
          var _function = {
            id: 0,
            name: element.name,
            type: element.type,
            type_name: element.type_name,
            action: element.action,
            action_name: element.action_name,
            delay: element.delay,
            next: element.next
          }
          console.log('_function');
          console.log(_function);
          ref.push().set(_function);
        });

        var current_date = new Date();
        firebase.database().ref("control/time").set(Math.floor(current_date.getTime() / 1000));
        firebase.database().ref("control/radio_update").set(true);
      }

      $scope.ResetFunctions = function() {
        console.log('FunctionSetupCtrl: ResetFunction');

        firebase.database().ref('Functions').remove();
        $scope.doRefresh();
      };

      $scope.UpdateType = function(RadioCode, item) {
        console.log('UpdateType');
        item = JSON.parse(item);
        console.log(item);
        RadioCode.type = parseInt(item.type);
        RadioCode.type_name = item.name;
        if (item.type == 1) {
          $scope.ActiveTable = $scope.Dout;
        } else if (item.type == 2) {
          $scope.ActiveTable = $scope.ActiveRadioCodesTx;
        } else if (item.type == 3) {
          $scope.ActiveTable = $scope.Lout;
        } else {
          $scope.ActiveTable = [];
        }
        console.log($scope.ActiveTable);
        console.log(RadioCode);
      };

      $scope.UpdateAction = function(RadioCode, item) {
        console.log('UpdateAction');
        item = JSON.parse(item);
        console.log(item);
        RadioCode.action = parseInt(item.id);
        RadioCode.action_name = item.name;
        console.log(RadioCode);
      };

      $scope.UpdateDelay = function(RadioCode, delay) {
        console.log('UpdateDelay');
        console.log(delay);
        RadioCode.delay = parseInt(delay);
        console.log(RadioCode);
      };

      $scope.UpdateNext = function(RadioCode, item) {
        console.log('UpdateAction_d');
        item = JSON.parse(item);
        console.log(item);
        RadioCode.next = item.name;
        console.log(RadioCode);
      };

      // Triggered on a button click, or some other target
      $scope.showPopupFunctionAdd = function() {
        var PopupTemplate =
          '<form class="list">' +
          '<h9 id="setup-heading5" style="text-align:left;">name</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="name" ng-model="settings._name"> </label>' +
          '</form>';

        // An elaborate, custom popup
        var myPopup = $ionicPopup.show({
          template: PopupTemplate,
          title: 'Function Configuration',
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
                var _Function = {
                  name: $scope.settings._name,
                  type: 0,
                  type_name: "",
                  action: 0,
                  action_name: "",
                  delay: 0,
                  next: ""
                };
                // console.log(_timer);
                $scope.Functions.push(_Function);

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
      $scope.showPopupFunctionEdit = function(data, i) {
        $scope.settings._name = data[i].name;
        var PopupTemplate =
          '<form class="list">' +
          '<h9 id="setup-heading5" style="text-align:left;">name</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="name" ng-model="settings._name"> </label>' +
          '</form>';

        // An elaborate, custom popup
        var myPopup = $ionicPopup.show({
          template: PopupTemplate,
          title: 'Function Configuration',
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
                data[i].name = $scope.settings._name;
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

        var ref = firebase.database().ref('Functions');
        var i = 0;
        $scope.Functions = [];
        ref.once('value', function(snapshot) {
          snapshot.forEach(function(childSnapshot) {
            // console.log(childSnapshot.val());
            $scope.Functions.push(childSnapshot.val());
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
