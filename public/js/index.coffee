$(document).ready () ->

  $("#name").focus()
  $("#name").change () ->
    $("#conversation").empty()
    socket.emit 'Hi', "I am " + $("#name").val()

  (socket = io.connect()).on "connect", () ->
    @on 'Welcome', (msg) ->
    @on 'message', (msg) -> display msg
    @on 'Joining', (msg) -> display msg + " joined"

    display = (msg) ->
      $("#conversation").append('<span class="shadow">' + msg + '</span><br>')
      $("#conversation").scrollTop $("#conversation")[0].scrollHeight
   
    sendMsg = () ->
      display $("#name").val() + ":   " + $("#msg").val()
      socket.send $("#msg").val()
      $("#msg").val('')
    
    $("#btn-send").click () -> sendMsg()
    
    $('#msg').keypress (e) ->
      if e.keyCode == 13
        sendMsg()
        return false
    

