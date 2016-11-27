angular.module('app.routes', [])

.config(function($stateProvider, $urlRouterProvider) {

  // Ionic uses AngularUI Router which uses the concept of states
  // Learn more here: https://github.com/angular-ui/ui-router
  // Set up the various states which the app can be in.
  // Each state's controller can be found in controllers.js
  $stateProvider

  .state('menu.Home', {
    url: '/Home',
    views: {
      'side-menu21': {
        templateUrl: 'templates/home.Html',
        controller: 'homeCtrl'
      }
    }
  })

  .state('menu.NodeSetup', {
    url: '/NodeSetup',
    views: {
      'side-menu21': {
        templateUrl: 'templates/NodeSetup.html',
        controller: 'NodeSetupCtrl'
      }
    }
  })

  .state('menu.chart', {
    url: '/chart',
    views: {
      'side-menu21': {
        templateUrl: 'templates/chart.html',
        controller: 'chartCtrl'
      }
    }
  })

  .state('menu.History', {
    url: '/History',
    views: {
      'side-menu21': {
        templateUrl: 'templates/History.html',
        controller: 'HistoryCtrl'
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

  .state('menu.RadioSetup', {
    url: '/page6',
    views: {
      'side-menu21': {
        templateUrl: 'templates/RadioSetup.html',
        controller: 'RadioSetupCtrl'
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

  .state('menu', {
    url: '/side-menu21',
    templateUrl: 'templates/menu.html',
    abstract:true
  })

  $urlRouterProvider.otherwise('/side-menu21/Home')

});
