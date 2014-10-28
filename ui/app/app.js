/*global require */
(function() {
  'use strict';


  var app = angular.module('annotator', ['ui.router', 'ngCkeditor', 'ngSanitize', 'ui.bootstrap']);

  require('./home.js')(app);
  app.config(['$stateProvider', '$locationProvider', function($stateProvider, $locationProvider) {
    $locationProvider.html5Mode(true);

    $stateProvider
      .state('home', {
        url: '/',
        templateUrl: 'src/home.html',
        controller: 'courseListCtrl as courseList',
        resolve: {}
      })
      .state('session', {
        url: '/sessions/',
        resolve: {},
        title: '<div>Hello {{$id}}!</div>',
        controller: 'sessionDetailCtrl as session',
        templateUrl: 'src/session/session.html'
      });
  }]);
})();
