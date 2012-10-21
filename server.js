(function() {
  var IO;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  IO = 10;
  module.exports = {
    start: function(callback) {
      var ChatConversation, G, Game, Games, OnlinePlayers, express;
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
      this.server.get('/points', function(req, res) {
        return res.render('points');
      });
      this.server.get('/stats', function(req, res) {
        return res.render('stats', {
          games: Games
        });
      });
      IO = require('socket.io').listen(this.server.listen(7777, callback));
      IO.set('log level', 1);
      Games = {};
      Game = (function() {
        function Game(host, game) {
          this.host = host;
          this.game = game;
        }
        Game.prototype.player_cnt = function() {
          return IO.sockets.clients(this.room()).length;
        };
        Game.prototype.room = function() {
          return "" + this.host + "-" + this.game;
        };
        Game.prototype.emit = function(e, m) {
          return IO.sockets["in"](this.room()).emit(e, m);
        };
        return Game;
      })();
      ChatConversation = [];
      IO.sockets.on('connection', function(player) {
        player.on('login', function(msg) {
          var g, h, name, _i, _len, _ref;
          if (name = (_ref = msg.match(/I am (.+)$/)) != null ? _ref[1] : void 0) {
            this.set('name', name);
            this.emit('welcome', "Logged in as " + name);
            this.emit('players', OnlinePlayers('name'));
            this.emit('games', (function() {
              var _results;
              _results = [];
              for (h in Games) {
                g = Games[h];
                _results.push((g.players = g.player_cnt(), g));
              }
              return _results;
            })());
            if (g = Games[name]) {
              this.join(g.room());
            }
            for (_i = 0, _len = ChatConversation.length; _i < _len; _i++) {
              msg = ChatConversation[_i];
              this.send(msg);
            }
            return player.broadcast.emit('login', name);
          } else {
            this.emit('sorry', "Try again later");
            return this.disconnect('unauthorized');
          }
        });
        player.on('message', function(msg) {
          return this.get('name', function(err, name) {
            if (name) {
              player.broadcast.send(name + ":   " + msg);
              return ChatConversation.push(name + ':   ' + msg);
            }
          });
        });
        player.on('host', function(msg) {
          return this.get('name', function(err, name) {
            var game;
            if (name) {
              game = new Game(name, msg.game);
              player.join(game.room());
              Games[name] = game;
              msg.host = name;
              msg.players = game.player_cnt();
              return player.broadcast.emit('host', msg);
            }
          });
        });
        player.on('join', function(msg) {
          return this.get('name', function(err, name) {
            var game;
            if (name) {
              game = Games[msg.host];
              player.join(game.room());
              return player.broadcast.emit('join', {
                guest: name,
                game: game.game
              });
            }
          });
        });
        player.on('start', function(msg) {
          return this.get('name', function(err, name) {
            if (name) {
              return Games[name].emit('start');
            }
          });
        });
        return player.on("move", function(msg) {
          var _ref;
          return (_ref = G(player)) != null ? typeof _ref.emit === "function" ? _ref.emit('move', msg) : void 0 : void 0;
        });
      });
      G = __bind(function(socket) {
        var obj, room, _ref;
        return IO.sockets["in"]((_ref = ((function() {
          var _ref2, _results;
          _ref2 = IO.sockets.manager.roomClients[socket.id];
          _results = [];
          for (room in _ref2) {
            obj = _ref2[room];
            _results.push(room);
          }
          return _results;
        })())[1]) != null ? _ref.slice(1) : void 0);
      }, this);
      return OnlinePlayers = __bind(function(p) {
        var i, s, _ref, _results;
        _ref = IO.sockets.sockets;
        _results = [];
        for (i in _ref) {
          s = _ref[i];
          if (s.store.data[p]) {
            _results.push(s.store.data[p]);
          }
        }
        return _results;
      }, this);
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
