(function() {
  var createPoint, logged_in, myColor, points;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  myColor = '#' + (Math.random() * 0xFFFFFF << 0).toString(16);
  points = {};
  logged_in = false;
  createPoint = function(id, color) {
    $(document.body).append("<div id=\"" + id + "\"> " + id + " </div>");
    return $("#" + id).css({
      'background-color': color,
      'position': 'absolute',
      'border-radius': '42px',
      'height': '84px',
      'width': '84px'
    });
  };
  $(document).ready(function() {
    var socket;
    $("#login").click(function() {
      $("#conversation").empty();
      socket.emit('login', "I am " + $("#name").val());
      return logged_in = true;
    });
    (socket = io.connect()).on("connect", function() {
      var display, sendMsg;
      this.on('login', function(msg) {
        return display(msg + " joined");
      });
      this.on('players', function(msg) {
        var p, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = msg.length; _i < _len; _i++) {
          p = msg[_i];
          _results.push(display("" + p + " is online"));
        }
        return _results;
      });
      this.on('games', __bind(function(hosted_games) {
        return this.emit('host', {
          game: 'eu.andlabs.gcp.examples.points'
        });
      }, this));
      $(document).mousemove(__bind(function(e) {
        return this.emit('move', {
          who: $("#name").val(),
          color: myColor,
          x: e.pageX - 42,
          y: e.pageY - 42
        });
      }, this));
      this.on('move', function(msg) {
        var _name;
        if (logged_in) {
          points[_name = msg.who] || (points[_name] = createPoint(msg.who, msg.color));
          return $("#" + msg.who).css({
            'left': msg.x,
            'top': msg.y
          });
        }
      });
      $("#send").click(function() {
        return sendMsg();
      });
      this.on('message', function(msg) {
        return display(msg);
      });
      display = function(msg) {
        $("#conversation").append('<span class="shadow">' + msg + '</span><br>');
        return $("#conversation").scrollTop($("#conversation")[0].scrollHeight);
      };
      sendMsg = function() {
        display($("#name").val() + ":   " + $("#msg").val());
        socket.send($("#msg").val());
        return $("#msg").val('');
      };
      return $('#msg').keypress(function(e) {
        if (e.keyCode === 13) {
          sendMsg();
          return false;
        }
      });
    });
    $("#name").val('');
    return $("#name").focus();
  });
}).call(this);
