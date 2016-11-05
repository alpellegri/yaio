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

  .state('menu.firebase', {
    url: '/page5',
    views: {
      'side-menu21': {
        templateUrl: 'templates/firebase.html',
        controller: 'firebaseCtrl'
      }
    }
  })

  .state('menu.node', {
    url: '/page2',
    views: {
      'side-menu21': {
        templateUrl: 'templates/node.html',
        controller: 'NodeCtrl'
      }
    }
  })

  .state('menu.radio', {
    url: '/page6',
    views: {
      'side-menu21': {
        templateUrl: 'templates/radio.html',
        controller: 'RadioCtrl'
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

  .state('menu.logger', {
    url: '/page4',
    views: {
      'side-menu21': {
        templateUrl: 'templates/logger.html',
        controller: 'loggerCtrl'
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
