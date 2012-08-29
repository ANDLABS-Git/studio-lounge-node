(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  module.exports = {
    start: function(callback) {
      var ChatConversation, G, Game, OnlinePlayers, OpenHostedGames, express;
      this.server = (express = require('express'))();
      this.server.set('views', "views");
      this.server.set('view engine', 'jade');
      this.server.use(express.bodyParser());
      this.server.use(express.static('public'));
      this.server.set('view options', {
        pretty: true
      });
      this.server.get('/', function(req, res) {
        return res.render('index');
      });
      this.io = require('socket.io').listen(this.server.listen(7777, callback));
      this.io.set('log level', 1);
      ChatConversation = [];
      this.io.sockets.on('connection', function(player) {
        player.on('login', function(msg) {
          var name, _i, _len, _ref;
          if (name = (_ref = msg.match(/I am (.+)$/)) != null ? _ref[1] : void 0) {
            this.set('name', name);
            this.emit('welcome', "Logged in as " + name);
            this.emit('players', OnlinePlayers('name'));
            this.emit('games', OpenHostedGames('name'));
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
            if (name) {
              player.join("" + name + "-" + msg.game);
              msg.host = name;
              return player.broadcast.emit('host', msg);
            }
          });
        });
        player.on('join', function(msg) {
          return this.get('name', function(err, name) {
            if (name) {
              Game(msg).emit('join', {
                guest: name
              });
              return player.join("" + msg.host + "-" + msg.game);
            }
          });
        });
        player.on('start', function(msg) {
          return this.get('name', function(err, name) {
            if (name) {
              return Game(msg).emit('start');
            }
          });
        });
        return player.on("move", function(msg) {
          return G(player).emit('move', msg);
        });
      });
      G = __bind(function(socket) {
        var obj, room;
        return this.io.sockets["in"](((function() {
          var _ref, _results;
          _ref = this.io.sockets.manager.roomClients[socket.id];
          _results = [];
          for (room in _ref) {
            obj = _ref[room];
            _results.push(room);
          }
          return _results;
        }).call(this))[1].slice(1));
      }, this);
      Game = __bind(function(msg) {
        return this.io.sockets["in"]("" + msg.host + "-" + msg.game);
      }, this);
      OnlinePlayers = __bind(function(p) {
        var i, s, _ref, _results;
        _ref = this.io.sockets.sockets;
        _results = [];
        for (i in _ref) {
          s = _ref[i];
          _results.push(s.store.data[p]);
        }
        return _results;
      }, this);
      return OpenHostedGames = __bind(function(p) {
        var game, host, players, room, _ref, _ref2, _results;
        _ref = this.io.sockets.manager.rooms;
        _results = [];
        for (room in _ref) {
          players = _ref[room];
          if (room !== '') {
            _ref2 = room.slice(1).split("-"), host = _ref2[0], game = _ref2[1];
            _results.push({
              game: game,
              host: host
            });
          }
        }
        return _results;
      }, this);
    },
    stop: function(callback) {
      this.io.server.close();
      return callback();
    },
    gcp: function() {
      return require('socket.io-client').connect("http://localhost:7777", {
        'force new connection': true
      });
    }
  };
}).call(this);
