angular.module('app.routes', [])

.config(function($stateProvider, $urlRouterProvider) {

  // Ionic uses AngularUI Router which uses the concept of states
  // Learn more here: https://github.com/angular-ui/ui-router
  // Set up the various states which the app can be in.
  // Each state's controller can be found in controllers.js
  $stateProvider

  .state('menu.home', {
    url: '/page1',
    views: {
      'side-menu21': {
        templateUrl: 'templates/home.html',
        controller: 'homeCtrl'
      }
    }
  })

  .state('menu.FirebaseSetup', {
    url: '/page5',
    views: {
      'side-menu21': {
        templateUrl: 'templates/FirebaseSetup.html',
        controller: 'FirebaseSetupCtrl'
      }
    }
  })

  .state('menu.NodeSetup', {
    url: '/page2',
    views: {
      'side-menu21': {
        templateUrl: 'templates/NodeSetup.html',
        controller: 'NodeSetupCtrl'
      }
    }
  })

  .state('menu.RadioSetup', {
    url: '/page6',
    views: {
      'side-menu21': {
        templateUrl: 'templates/RadioSetup.html',
        controller: 'RadioSetupCtrl'
      }
    }
  })

  .state('menu.chart', {
    url: '/page3',
    views: {
      'side-menu21': {
        templateUrl: 'templates/chart.html',
        controller: 'chartCtrl'
      }
    }
  })

  .state('menu.History', {
    url: '/page4',
    views: {
      'side-menu21': {
        templateUrl: 'templates/History.html',
        controller: 'HistoryCtrl'
      }
    }
  })

  .state('menu.NodeInfo', {
    url: '/page7',
    views: {
      'side-menu21': {
        templateUrl: 'templates/NodeInfo.html',
        controller: 'NodeInfoCtrl'
      }
    }
  })

  .state('menu.TimerSetup', {
    url: '/page8',
    views: {
      'side-menu21': {
        templateUrl: 'templates/TimerSetup.html',
        controller: 'TimerSetupCtrl'
      }
    }
  })

  .state('menu.DigitalIOSetup', {
    url: '/page9',
    views: {
      'side-menu21': {
        templateUrl: 'templates/DigitalIOSetup.html',
        controller: 'DigitalIOSetupCtrl'
      }
    }
  })

  .state('menu.LogicalIOSetup', {
    url: '/page10',
    views: {
      'side-menu21': {
        templateUrl: 'templates/LogicalIOSetup.html',
        controller: 'LogicalIOSetupCtrl'
      }
    }
  })

  .state('menu.FunctionSetup', {
    url: '/page11',
    views: {
      'side-menu21': {
        templateUrl: 'templates/FunctionSetup.html',
        controller: 'FunctionSetupCtrl'
      }
    }
  })

  .state('menu', {
    url: '/side-menu21',
    templateUrl: 'templates/menu.html',
    abstract:true
  })

  $urlRouterProvider.otherwise('/side-menu21/page1')

});
