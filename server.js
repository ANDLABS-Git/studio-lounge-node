(function() {
  var IO;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  IO = 10;
  module.exports = {
    start: function(callback) {
      var ChatConversation, G, Game, Games, Hosted, OnlinePlayers, State, express;
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
      Hosted = {};
      Game = (function() {
        function Game(host, msg) {
          this.host = host;
          this.id = "" + msg.game + "-" + (((1 + Math.random()) * 0x1000000 | 0).toString(16).substring(1));
          Hosted[this.host] = this;
          Games[this.id] = this;
          this.players = [];
          this.min = msg.min;
          this.max = msg.max;
          this.players.push(this.host);
        }
        Game.prototype.emit = function(e, m) {
          return IO.sockets["in"](this.game).emit(e, m);
        };
        return Game;
      })();
      ChatConversation = [];
      IO.sockets.on('connection', function(player) {
        player.on('login', function(msg) {
          var g, name, _i, _len, _ref;
          if (name = (_ref = msg.match(/I am (.+)$/)) != null ? _ref[1] : void 0) {
            this.set('name', name);
            this.emit('welcome', "Logged in as " + name);
            if (g = Hosted[name]) {
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
              return ChatConversation.push({
                player: name,
                msg: msg
              });
            }
          });
        });
        player.on('host', function(msg) {
          return this.get('name', __bind(function(err, name) {
            var game;
            if (name) {
              game = new Game(name, msg);
              msg.game = game.id;
              msg.host = name;
              this.join(game.id);
              return IO.sockets.emit('host', msg);
            }
          }, this));
        });
        player.on('state', function(msg) {
          return this.emit('state', State());
        });
        player.on('join', function(msg) {
          return this.get('name', __bind(function(err, name) {
            var game;
            if (name) {
              game = Games[msg.game];
              if (game.players.length < game.max) {
                game.players.push(name);
                this.join(game.id);
                msg.guest = name;
                IO.sockets.emit('join', msg);
                if (game.players.length === game.max) {
                  Hosted[game.host] = void 0;
                  return IO.sockets.emit('unhost', {
                    host: game.host,
                    game: game.id
                  });
                }
              }
            }
          }, this));
        });
        player.on('games', function(msg) {
          var game, id;
          return this.emit('games', (function() {
            var _results;
            _results = [];
            for (id in Games) {
              game = Games[id];
              _results.push({
                game: id,
                players: game.players
              });
            }
            return _results;
          })());
        });
        player.on('move', function(msg) {
          var _ref;
          return (_ref = G(player)) != null ? typeof _ref.emit === "function" ? _ref.emit('move', msg) : void 0 : void 0;
        });
        return player.on('logout', function(msg) {
          return this.get('name', __bind(function(err, name) {
            if (name) {
              return IO.sockets.emit('logout', name);
            }
          }, this));
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
      OnlinePlayers = __bind(function(p) {}, this);
      return State = function() {
        var game, i, name, s;
        return {
          players: (function() {
            var _ref, _results;
            _ref = IO.sockets.sockets;
            _results = [];
            for (i in _ref) {
              s = _ref[i];
              if (s.store.data['name']) {
                name = s.store.data['name'];
                _results.push((game = Hosted[name]) ? {
                  name: name,
                  game: {
                    id: game.id,
                    min: game.min,
                    max: game.max,
                    joined: game.players.length
                  }
                } : {
                  name: name
                });
              }
            }
            return _results;
          })(),
          chat: ChatConversation,
          games_played: Object.keys(Games).length,
          msges_sent: ChatConversation.length
        };
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
