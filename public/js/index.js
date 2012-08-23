(function() {
  $(document).ready(function() {
    var socket;
    $("#name").focus();
    $("#name").change(function() {
      $("#conversation").empty();
      return socket.emit('Hi', "I am " + $("#name").val());
    });
    return (socket = io.connect()).on("connect", function() {
      var display, sendMsg;
      this.on('Welcome', function(msg) {});
      this.on('message', function(msg) {
        return display(msg);
      });
      this.on('Joining', function(msg) {
        return display(msg + " joined");
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
      $("#btn-send").click(function() {
        return sendMsg();
      });
      return $('#msg').keypress(function(e) {
        if (e.keyCode === 13) {
          sendMsg();
          return false;
        }
      });
    });
  });
}).call(this);
