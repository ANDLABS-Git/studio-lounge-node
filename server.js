(function() {
  var Server;
  Server = (function() {
    function Server() {}
    Server.prototype.start = function(callback) {
      var ChatConversation, express;
      this.server = (express = require('express'))();
      this.server.set('views', "views");
      this.server.use(express.bodyParser());
      this.server.set('view engine', 'jade');
      this.server.use(express.static('public'));
      this.server.set('view options', {
        pretty: true
      });
      this.server.get('/', function(req, res) {
        return res.render('index', {
          title: "hAppy Log"
        });
      });
      this.io = require('socket.io').listen(this.server.listen(7777, callback));
      ChatConversation = [];
      this.io.sockets.on('connection', function(player) {
        player.on('Hi', function(msg) {
          var name, _i, _len, _ref;
          if (name = (_ref = msg.match(/I am (.+)$/)) != null ? _ref[1] : void 0) {
            this.set('name', name);
            this.emit('Welcome', "Logged in as " + name);
            for (_i = 0, _len = ChatConversation.length; _i < _len; _i++) {
              msg = ChatConversation[_i];
              this.send(msg);
            }
            return player.broadcast.emit('Joining', name);
          } else {
            this.emit('Sorry', "Try again later...");
            return this.disconnect('unauthorized');
          }
        });
        return player.on('message', function(msg) {
          return this.get('name', function(err, name) {
            player.broadcast.send(name + ":   " + msg);
            return ChatConversation.push(name + ':   ' + msg);
          });
        });
      });
      return this.io.set('log level', 1);
    };
    Server.prototype.stop = function(callback) {
      this.io.server.close();
      return callback();
    };
    Server.prototype.game = function() {
      return require('socket.io-client').connect("http://localhost:7777", {
        'force new connection': true
      });
    };
    return Server;
  })();
  module.exports = new Server();
}).call(this);
