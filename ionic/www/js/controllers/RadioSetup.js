angular.module('app.controllers.RadioSetup', [])

  .controller('RadioSetupCtrl', function($scope, $ionicPopup, $timeout) {
    console.log('RadioSetupCtrl');

    var fb_init = localStorage.getItem('firebase_init');
    if (fb_init == 'true') {

      $scope.pushCtrl0 = {
        checked: false
      };
      $scope.pushCtrl1 = {
        checked: false
      };

      $scope.settings = {};
      $scope.InactiveRadioCodes = [];
      $scope.ActiveRadioCodes = [];
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
      $scope.RemoveInactiveRadioCode = function(i) {
        $scope.InactiveRadioCodes.splice(i, 1);
      };

      // move radio code to active
      $scope.ActivateRadioCode = function(data, i) {
        var radio = {
          name: "default",
          id: $scope.InactiveRadioCodes[i],
          type: 0,
          action: 0,
          delay: 0,
          action_d: 0
        }
        data.push(radio);
        $scope.InactiveRadioCodes.splice(i, 1);
      };

      // remove radio code
      $scope.RemoveActiveRadioCode = function(data, i) {
        data.splice(i, 1);
      };

      // move radio code to inactive
      $scope.DeactivateRadioCode = function(data, i) {
        $scope.InactiveRadioCodes.push(data[i].id);
        data.splice(i, 1);
      };

      $scope.SetupRadio = function() {
        var ref = firebase.database().ref("RadioCodes");
        ref.child('Active').remove();
        console.log('active');
        $scope.ActiveRadioCodes.forEach(function(element) {
          console.log('element');
          console.log(element);
          var radio = {
            name: element.name,
            id: element.id,
            type: element.type,
            action: element.action,
            delay: element.delay,
            action_d: element.action_d
          }
          console.log('radio');
          console.log(radio);
          ref.child('Active').push().set(radio);
        });

        ref.child('ActiveTx').remove();
        console.log('active tx');
        $scope.ActiveRadioCodesTx.forEach(function(element) {
          console.log(element);
          var radio = {
            name: element.name,
            id: element.id
          }
          console.log(radio);
          ref.child('ActiveTx').push().set(radio);
        });

        ref.child('Inactive').remove();
        console.log('inactive');
        $scope.InactiveRadioCodes.forEach(function(element) {
          ref.child('Inactive').push().set(element);
        });
      }

      $scope.UpdateType = function(RadioCode, type) {
        console.log('UpdateType');
        console.log(type);
        RadioCode.type = parseInt(type);
        if (type == 1) {
          $scope.ActiveTable = $scope.Dout;
        } else if (type == 2) {
          $scope.ActiveTable = $scope.ActiveRadioCodesTx;
        } else {}
      };

      $scope.UpdateAction = function(RadioCode, action) {
        console.log('UpdateAction');
        console.log(action);
        RadioCode.action = parseInt(action);
        console.log(RadioCode);
      };

      $scope.UpdateDelay = function(RadioCode, delay) {
        console.log('UpdateActionDelayed');
        console.log(delay);
        RadioCode.delay = parseInt(delay);
        console.log(RadioCode);
      };

      $scope.UpdateActionDelayed = function(RadioCode, action) {
        console.log('UpdateActionDelayed');
        console.log(action);
        RadioCode.action_d = parseInt(action);
        console.log(RadioCode);
      };

      $scope.pushCtrl0Change = function() {
        var ref = firebase.database().ref("control");
        console.log('radio_learn control ' + $scope.pushCtrl0.checked);
        if ($scope.pushCtrl0.checked) {
          ref.update({
            radio_learn: true
          });
        } else {
          ref.update({
            radio_learn: false
          });
        }
      };

      $scope.pushCtrl1Change = function() {
        var ref = firebase.database().ref("control");
        console.log('radio_update control ' + $scope.pushCtrl1.checked);
        if ($scope.pushCtrl1.checked) {
          ref.update({
            radio_update: true
          });
        } else {
          ref.update({
            radio_update: false
          });
        }
      };

      $scope.ResetRadioCodes = function() {
        console.log('RadioSetupCtrl: ResetRadioCodes');

        firebase.database().ref('RadioCodes').remove();
        $scope.doRefresh();
      };

      // Triggered on a button click, or some other target
      $scope.showPopupRadioEdit = function(data, i) {
        $scope.settings._name = data[i].name;
        $scope.settings._id = data[i].id;
        var PopupTemplate =
          '<form class="list">' +
          '<h9 id="setup-heading5" style="text-align:left;">name</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="name" ng-model="settings._name"> </label>' +
          '<h9 id="setup-heading5" style="text-align:left;">id</h9>' +
          '<label class="item item-input"> <input type="text" placeholder="id" ng-model="settings._id"> </label>' +
          '</form>';

        // An elaborate, custom popup
        var myPopup = $ionicPopup.show({
          template: PopupTemplate,
          title: 'Radio Configuration',
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
                data[i].id = $scope.settings._id;
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

        var ref = firebase.database().ref('RadioCodes/Inactive');
        var i = 0;
        $scope.InactiveRadioCodes = [];
        ref.once('value', function(snapshot) {
          snapshot.forEach(function(childSnapshot) {
            // console.log(childSnapshot.val());
            $scope.InactiveRadioCodes.push(childSnapshot.val());
            i++;
          });
        });

        var ref = firebase.database().ref('RadioCodes/Active');
        var i = 0;
        $scope.ActiveRadioCodes = [];
        ref.once('value', function(snapshot) {
          snapshot.forEach(function(childSnapshot) {
            // console.log(childSnapshot.val());
            $scope.ActiveRadioCodes.push(childSnapshot.val());
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

        var ref = firebase.database().ref("control/radio_learn");
        // Attach an asynchronous callback to read the data at our posts reference
        ref.on('value', function(snapshot) {
          var payload = snapshot.val();

          if (payload == true) {
            $scope.pushCtrl0.checked = true;
          } else {
            $scope.pushCtrl0.checked = false;
          }
        }, function(errorObject) {
          console.log("firebase failed: " + errorObject.code);
        });

        // $scope.$broadcast("scroll.infiniteScrollComplete");
        $scope.$broadcast('scroll.refreshComplete');
      };

      $scope.doRefresh();
    }
  })
