(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  $(document).ready(function() {
    var socket;
    return (socket = io.connect()).on("connect", function() {
      var display;
      socket.emit('login', "I am stat bot");
      this.players = 0;
      this.games = {};
      this.on('players', __bind(function(players) {
        this.players = players.length;
        return $("#players").text("ONLINE: " + this.players);
      }, this));
      this.on('login', function(msg) {
        this.players += 1;
        return $("#players").text("ONLINE: " + this.players);
      });
      this.on('games', __bind(function(games) {
        var g, _i, _len;
        for (_i = 0, _len = games.length; _i < _len; _i++) {
          g = games[_i];
          this.games[g.host] = g;
        }
        return display();
      }, this));
      this.on('host', __bind(function(game) {
        this.games[game.host] = game;
        return display();
      }, this));
      this.on('join', __bind(function(msg) {
        this.games[msg.host].players += 1;
        return display();
      }, this));
      return display = __bind(function() {
        var game, h, _ref, _results;
        $("#games").empty();
        _ref = this.games;
        _results = [];
        for (h in _ref) {
          game = _ref[h];
          _results.push($("#games").append("<h3>" + game.host + "</h3>                            <ul><li>Host: " + game.game + "</li>                              <li>Players: " + game.players + "</li></ul>"));
        }
        return _results;
      }, this);
    });
  });
}).call(this);
