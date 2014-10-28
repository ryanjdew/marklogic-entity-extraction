
angular.module('sample', [
  'ngRoute', 'ngCkeditor', 'sample.user', 'sample.search', 'sample.common', 'sample.detail',
  'ui.bootstrap', 'gd.ui.jsonexplorer', 'sample.create'
])
  .config(['$routeProvider', '$locationProvider', function ($routeProvider, $locationProvider) {

    'use strict';

    $locationProvider.html5Mode(true);

    $routeProvider
      .when('/', {
        templateUrl: '/search/search.html'
      })
      .when('/create', {
        templateUrl: '/create/create.html',
        controller: 'CreateCtrl'
      })
      .when('/detail', {
        templateUrl: '/detail/detail.html',
        controller: 'DetailCtrl'
      })
      .when('/profile', {
        templateUrl: '/user/profile.html',
        controller: 'ProfileCtrl'
      })
      .otherwise({
        redirectTo: '/'
      });
  }]);


angular.module('sample.common', []);

(function () {
  'use strict';

  angular.module('sample.detail')
    .controller('DetailCtrl', ['$scope', 'MLRest', '$routeParams', function ($scope, mlRest, $routeParams) {
      var uri = $routeParams.uri;
      var model = {
        // your model stuff here
        detail: {}
      };

      mlRest.getDocument(uri, { format: 'json' }).then(function(response) {
        model.detail = response.data;
      });

      angular.extend($scope, {
        model: model

      });
    }]);
}());


angular.module('sample.detail', []);

// Copied from https://docs.angularjs.org/api/ng/service/$compile
angular.module('sample.create')
  .directive('compile', function($compile) {
    'use strict';
    // directive factory creates a link function
    return function(scope, element, attrs) {
      scope.$watch(
        function(scope) {
           // watch the 'compile' expression for changes
          return scope.$eval(attrs.compile);
        },
        function(value) {
          // when the 'compile' expression changes
          // assign it into the current DOM
          element.html(value);

          // compile the new DOM and link it to the current
          // scope.
          // NOTE: we only compile .childNodes so that
          // we don't get into infinite loop compiling ourselves
          $compile(element.contents())(scope);
        }
      );
    };
  });

(function () {
  'use strict';

  angular.module('sample.create')
    .controller('CreateCtrl', ['$scope', 'MLRest', 'Features', '$window', function ($scope, mlRest, features, win) {
      var model = {
        demo: {
          name: '',
          description: '',
          host: '',
          hostType: 'internal',
          browsers: [],
          features: [],
          languages: [],
          bugs: [],
          comments: []
        },
        featureChoices: features.list(),
        browserChoices: ['Firefox', 'Chrome', 'IE']
      };

      angular.extend($scope, {
        model: model,
        editorOptions: {
          height: '100px',
          toolbarGroups: [
            { name: 'clipboard',   groups: [ 'clipboard', 'undo' ] },
            { name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] }
          ],
          //override default options
          toolbar: '',
          /* jshint camelcase: false */
          toolbar_full: ''
        },
        updateBrowsers: function(browser) {
          var index = $scope.model.demo.browsers.indexOf(browser);
          if (index > -1) {
            $scope.model.demo.browsers.splice(index, 1);
          } else {
            $scope.model.demo.browsers.push(browser);
          }
        },
        submit: function() {
          mlRest.createDocument($scope.model.demo, {
            format: 'json',
            directory: '/demos/',
            extension: '.json',
            'perm:demo-cat-role': 'read',
            'perm:demo-cat-registered-role': 'update'
          }).then(function(data, status, headers, config) {
            win.location.href = '/detail?uri=' + headers('location').replace(/(.*\?uri=)/, '');
          });
        }
      });
    }]);
}());


angular.module('sample.create', []);

(function () {

  'use strict';

  var module = angular.module('sample.search');

  module.directive('facets', [function () {
    return {
      restrict: 'E',
      scope: {
        facets: '=facetList',
        selected: '=selected',
        select: '&select',
        clear: '&clear'
      },
      templateUrl: '/search/facets-dir.html',
      link: function() {
      }
    };
  }]);
}());

(function () {

  'use strict';

  var module = angular.module('sample.search');

  module.directive('results', [function () {
    return {
      restrict: 'E',
      scope: {
        results: '=resultList',
        total: '=total',
        start: '=start',
        pageLength: '=pageLength',
        currentPage: '=currentPage',
        paginate: '&paginate',
        updateQuery: '&updateQuery'
      },
      templateUrl: '/search/results-dir.html',
      link: function(scope) {
        scope.Math = window.Math;
      }
    };
  }]);
}());

(function () {
  'use strict';

  angular.module('sample.search')
    .controller('SearchCtrl', ['$scope', 'MLRest', 'User', '$location', function ($scope, mlRest, user, $location) {
      var model = {
        selected: [],
        text: '',
        user: user
      };

      var searchContext = mlRest.createSearchContext();

      function updateSearchResults(data) {
        model.search = data;
      }

      (function init() {
        searchContext
          .search()
          .then(updateSearchResults);
      })();

      angular.extend($scope, {
        model: model,
        selectFacet: function(facet, value) {
          var existing = model.selected.filter( function( selectedFacet ) {
            return selectedFacet.facet === facet && selectedFacet.value === value;
          });
          if ( existing.length === 0 ) {
            model.selected.push({facet: facet, value: value});
            searchContext
              .selectFacet(facet, value)
              .search()
              .then(updateSearchResults);
          }
        },
        clearFacet: function(facet, value) {
          var i;
          for (i = 0; i < model.selected.length; i++) {
            if (model.selected[i].facet === facet && model.selected[i].value === value) {
              model.selected.splice(i, 1);
              break;
            }
          }
          searchContext
            .clearFacet(facet, value)
            .search()
            .then(updateSearchResults);
        },
        textSearch: function() {
          searchContext
            .setText(model.text)
            .search()
            .then(updateSearchResults);
          $location.path('/');
        },
        pageChanged: function(page) {
          searchContext
            .setPage(page, model.pageLength)
            .search()
            .then(updateSearchResults);
        }
      });

      $scope.$watch('model.user.authenticated', function(newValue, oldValue) {
        // authentication status has changed; rerun search
        searchContext.search().then(updateSearchResults, function(error) {
          model.search = {};
        });
      });

    }]);
}());


angular.module('sample.search', []);

(function () {
  'use strict';

  angular.module('sample.user')
    .controller('ProfileCtrl', ['$scope', 'MLRest', 'User', '$location', function ($scope, mlRest, user, $location) {
      var model = {
        user: user, // GJo: a bit blunt way to insert the User service, but seems to work
        newEmail: ''
      };

      angular.extend($scope, {
        model: model,
        addEmail: function() {
          if ($scope.profileForm.newEmail.$error.email) {
            return;
          }
          if (!$scope.model.user.emails) {
            $scope.model.user.emails = [];
          }
          $scope.model.user.emails.push(model.newEmail);
          model.newEmail = '';
        },
        removeEmail: function(index) {
          $scope.model.user.emails.splice(index, 1);
        },
        submit: function() {
          mlRest.updateDocument({
            user: {
              'fullname': $scope.model.user.fullname,
              'emails': $scope.model.user.emails
            }
          }, {
            format: 'json',
            uri: '/users/' + $scope.model.user.name + '.json',
            'perm:demo-cat-role': 'read',
            'perm:demo-cat-registered-role': 'update'
          }).then(function(data) {
            $location.path('/');
          });
        }
      });
    }]);
}());

(function () {

  'use strict';

  var module = angular.module('sample.user');

  module.directive('mlUser', [function () {
    return {
      restrict: 'A',
      controller: 'UserController',
      replace: true,
      scope: {
        username: '=username',
        password: '=password',
        authenticated: '=authenticated',
        login: '&login',
        logout: '&logout',
        loginerror: '=loginerror'
      },
      templateUrl: '/user/user-dir.html',
      link: function($scope) {

      }
    };
  }])
  .controller('UserController', ['$scope', 'User', '$http', '$location', function ($scope, user, $http, $location) {
    angular.extend($scope, {
      login: function(username, password) {
        $http.get(
          '/user/login',
          {
            params: {
              'username': username,
              'password': password
            }
          }).then(function (result) {
            user.authenticated = result.data.authenticated;
            if (user.authenticated === true) {
              user.loginError = false;
              if (result.data.profile !== undefined) {
                user.fullname = result.data.profile.fullname;
                user.emails = result.data.profile.emails;
              } else {
                $location.path('/profile');
              }
            } else {
              user.loginError = true;
            }
          });
      },
      logout: function() {
        $http.get(
          '/user/logout',
          {}).then(function() {
            user.init();
          });
      }

    });
  }]);
}());

(function () {
  'use strict';

  angular.module('sample.user')
  .factory('User', ['$http', function($http) {
    var user = {};

    function updateUser(response) {
      var data = response.data;
      if (data.authenticated === true) {
        user.name = data.username;
        user.authenticated = true;
        if (data.profile !== undefined) {
          user.hasProfile = true;

          user.fullname = data.profile.fullname;

          if ($.isArray(data.profile.emails)) {
            user.emails = data.profile.emails;
          } else {
            // wrap single value in array, needed for repeater
            user.emails = [data.profile.emails];
          }
        }
      }
    }

    $http.get('/user/status', {}).then(updateUser);

    user.init = function init() {
      user.name = '';
      user.password = '';
      user.loginError = false;
      user.authenticated = false;
      user.hasProfile = false;
      user.fullname = '';
      user.emails = [];
      return user;
    };

    return user;
  }]);
}());


angular.module('sample.user', ['sample.common']);

(function () {
  'use strict';

  angular.module('sample.common')
    .provider('MLRest', function() {

      // Rewrite the data.results part of the response from /v1/search so that the metadata section in each is easier
      // to work with.
      function rewriteResults(results) {
        var rewritten = [];
        var revised = {};
        var metadata, j, key, prop;

        for (var i in results) {
          if (results.hasOwnProperty(i)) {
            revised = {};
            for (prop in results[i]) {
              if (results[i].hasOwnProperty(prop)) {
                if (prop === 'metadata') {
                  metadata = {};
                  for (j in results[i].metadata) {
                    if (results[i].metadata.hasOwnProperty(j)) {
                      for (key in results[i].metadata[j]) {
                        if (results[i].metadata[j].hasOwnProperty(key)) {
                          if (metadata[key]) {
                            metadata[key].push(results[i].metadata[j][key]);
                          } else {
                            metadata[key] = [ results[i].metadata[j][key] ];
                          }
                        }
                      }
                    }
                  }
                  revised.metadata = metadata;
                } else {
                  revised[prop] = results[i][prop];
                }
              }
            }

            rewritten.push(revised);
          }
        }

        return rewritten;
      }

      function SearchContext(options, $q, $http) {
        options = options || {};

        var boostQueries = [];
        var facetSelections = {};
        var textQuery = null;
        var snippet = 'compact';
        var sort = null;
        var start = 1;


        (function init(){
          options.queryOptions = options.queryOptions ? options.queryOptions : 'all';
          options.pageLength = options.pageLength ? options.pageLength : 10;
        })();

        function runSearch() {
          var d = $q.defer();
          $http.get(
            '/v1/search',
            {
              params: {
                format: 'json',
                options: options.queryOptions,
                structuredQuery: getStructuredQuery(),
                start: start,
                pageLength: options.pageLength
              }
            })
          .success(
            function(data) {
              data.results = rewriteResults(data.results);
              d.resolve(data);
            })
          .error(
            function(reason) {
              d.reject(reason);
            });
          return d.promise;
        }

        function buildFacetQuery(queries) {
          var facet;
          for (facet in facetSelections) {
            if (facetSelections.hasOwnProperty(facet) && facetSelections[facet].length > 0) {
              // TODO: derive constraint type from search options!
              if (facet === 'Dataset') {
                queries.push(
                  {
                    'collection-constraint-query': {
                      'constraint-name': 'Dataset',
                      'uri': [facetSelections[facet]]
                    }
                  }
                );
              } else if (options.customConstraintNames !== undefined && options.customConstraintNames.indexOf(facet) > -1) {
                queries.push(
                  {
                    'custom-constraint-query' : {
                      'constraint-name': facet,
                      'value': facetSelections[facet]
                    }
                  }
                );
              } else  {
                queries.push(
                  {
                    'range-constraint-query' : {
                      'constraint-name': facet,
                      'value': facetSelections[facet]
                    }
                  }
                );
              }
            }
          }
        }

        function getStructuredQuery() {
          var queries = [];
          var structured;

          buildFacetQuery(queries);

          if (textQuery !== null) {
            queries.push({
              'qtext': textQuery
            });
          }

          if (boostQueries.length > 0) {
            structured = {
              query: {
                'queries': [{
                  'boost-query': {
                    'matching-query': {
                      'and-query': {
                        'queries': queries
                      }
                    },
                    'boosting-query': {
                      'and-query': {
                        'queries': boostQueries
                      }
                    }
                  }
                }]
              }
            };
          } else {
            structured = {
              query: {
                'queries': [{
                  'and-query': {
                    'queries': queries
                  }
                }]
              }
            };
          }

          if (options.includeProperties) {
            structured = {
              query: {
                'queries': [{
                  'or-query': {
                    'queries': [
                      structured,
                      { 'properties-query': structured }
                    ]
                  }
                }]
              }
            };
          }

          if (sort) {
            // TODO: this assumes that the sort operator is called "sort", but 
            // that isn't necessarily true. Properly done, we'd get the options 
            // from the server and find the operator that contains sort-order
            // elements
            structured.query.queries.push({
              'operator-state': {
                'operator-name': 'sort',
                'state-name': sort
              }
            });
          }

          if (snippet) {
            structured.query.queries.push({
              'operator-state': {
                'operator-name': 'results',
                'state-name': snippet
              }
            });
          }

          return structured;
        }

        return {
          selectFacet: function(facet, value) {
            if (facetSelections.facet === undefined) {
              facetSelections[facet] = [value];
            } else {
              facetSelections[facet].push(value);
            }
            return this;
          },
          clearFacet: function(facet, value) {
            facetSelections[facet] = facetSelections[facet].filter( function( facetValue ) {
              return facetValue !== value;
            });
            return this;
          },
          clearAllFacets: function() {
            facetSelections = {};
            return this;
          },
          getQueryOptions: function() {
            return options.queryOptions;
          },
          getStructuredQuery: getStructuredQuery,
          search: function() {
            return runSearch();
          },
          setText: function(text) {
            if (text !== '') {
              textQuery = text;
            } else {
              textQuery = null;
            }
            return this;
          },
          setPage: function(page) {
            start = 1 + (page - 1) * options.pageLength;
            return this;
          },
          sortBy: function(sortField) {
            sort = sortField;
            return this;
          }
        };
      }

      this.$get = function($q, $http) {
        var service = {
          createSearchContext: function(options) {
            return new SearchContext(options, $q, $http);
          },
          getDocument: function(uri, options) {
            if (options === undefined || options === null) {
              options = {};
            }
            angular.extend(options, {
              format: 'json',
              uri: uri
            });
            return $http.get(
              '/v1/documents',
              {
                params: options
              });
          },
          createDocument: function(doc, options) {
            // send a POST request to /v1/documents
            return $http.post(
              '/v1/documents',
              doc,
              {
                params: options
              });
          },
          updateDocument: function(doc, options) {
            // send a PUT request to /v1/documents
            var d = $q.defer();
            $http.put(
              '/v1/documents',
              doc,
              {
                params: options
              })
              .success(function(data, status, headers, config) {
                d.resolve(headers('location'));
              }).error(function(reason) {
                d.reject(reason);
              });
            return d.promise;
          },
          patch: function(uri, patch) {
            var d = $q.defer();
            $http.post(
              '/v1/documents',
              patch,
              {
                params: {
                  uri: uri
                },
                headers: {
                  'X-HTTP-Method-Override': 'PATCH',
                  'Content-Type': 'application/json'
                }
              }
            )
            .success(
              function(data, status, headers, config) {
                d.resolve(headers('location'));
              })
            .error(
              function(reason) {
                d.reject(reason);
              });
            return d.promise;
          },
          advancedCall: function(url, settings) {
            var d = $q.defer();
            var method = settings.method;
            var isSupportedMethod = (method === 'GET' || method === 'PUT' || method === 'POST' || method === 'DELETE');
            method = isSupportedMethod ? method : 'POST';
            if (!isSupportedMethod) {
              settings.headers = settings.headers || {};
              settings.headers['X-HTTP-Method-Override'] = settings.method;
            }

            $http(
              {
                url: url,
                data: settings.data,
                method: method,
                params: settings.params,
                headers: settings.headers
              }
            )
            .success(
              function(data, status, headers, config) {
                d.resolve(data);
              })
            .error(function(reason) {
                d.reject(reason);
              });
            return d.promise;
          },
          callExtension: function(extensionName, settings) {
            return this.advancedCall('/v1/resources/'+extensionName, settings);
          }
        };

        return service;
      };
    });
}());
