(function() {
  var IO;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  IO = 10;
  module.exports = {
    start: function(callback) {
      var History, RandomGUID, SelectNext, express;
      this.server = (express = require('express'))();
      this.server.set('views', "views");
      this.server.set('view engine', 'jade');
      this.server.use(express.bodyParser());
      this.server.use(express.static('public'));
      this.server.set('view options', {
        pretty: true
      });
      this.server.get('/', function(req, res) {
        return res.render('points');
      });
      IO = require('socket.io').listen(this.server.listen(7777, callback));
      IO.set('log level', 1);
      History = [];
      IO.sockets.on('connection', function(player) {
        player.on('login', function(msg) {
          var name, _ref;
          if (name = (_ref = msg.match(/I am (.+)$/)) != null ? _ref[1] : void 0) {
            this.set('name', name);
            return this.emit('welcome', "Logged in as " + name);
          } else {
            this.emit('sorry', "Try again later");
            return this.disconnect('unauthorized');
          }
        });
        player.on('chat', function(text) {
          return this.get('name', function(err, name) {
            var msg;
            if (name) {
              msg = {
                text: text,
                sender: name
              };
              IO.sockets.emit('chat', msg);
              return History.push({
                what: 'chat',
                msg: msg
              });
            }
          });
        });
        player.on('host', function(match) {
          return this.get('name', __bind(function(err, name) {
            if (name) {
              match.id = RandomGUID();
              match.host = name;
              this.join(match.id);
              IO.sockets.emit('host', match);
              return History.push({
                what: 'host',
                msg: match
              });
            }
          }, this));
        });
        player.on('join', function(match) {
          return this.get('name', __bind(function(err, name) {
            if (name) {
              this.join(match.id);
              match.player = name;
              IO.sockets.emit('join', match);
              return History.push({
                what: 'join',
                msg: match
              });
            }
          }, this));
        });
        player.on('msg', function(msg) {
          return this.get('name', __bind(function(err, name) {
            if (name) {
              msg.sender = name;
              msg.next = SelectNext(msg.match, name);
              IO.sockets["in"](msg.match).emit('msg', msg);
              return History.push({
                what: 'msg',
                msg: msg
              });
            }
          }, this));
        });
        player.on('history', function(msg) {
          var m, _i, _len, _results;
          _results = [];
          for (_i = 0, _len = History.length; _i < _len; _i++) {
            m = History[_i];
            _results.push(this.emit(m.what, m.msg));
          }
          return _results;
        });
        return player.on('logout', function(msg) {
          return console.log("logout");
        });
      });
      RandomGUID = function() {
        return ((1 + Math.random()) * 0x1000000 | 0).toString(16).substring(1);
      };
      return SelectNext = function(match, activePlayer) {
        var n, s;
        return ((function() {
          var _i, _len, _ref, _results;
          _ref = (function() {
            var _j, _len, _ref, _results2;
            _ref = IO.sockets.clients(match);
            _results2 = [];
            for (_j = 0, _len = _ref.length; _j < _len; _j++) {
              s = _ref[_j];
              _results2.push(s.store.data.name);
            }
            return _results2;
          })();
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            n = _ref[_i];
            if (n !== activePlayer) {
              _results.push(n);
            }
          }
          return _results;
        })())[0];
      };
    },
    stop: function(callback) {
      IO.server.close();
      return callback();
    },
    gcp: function() {
      return require('socket.io-client').connect("http://localhost:7777", {
        'force new connection': true
      });
    }
  };
}).call(this);
