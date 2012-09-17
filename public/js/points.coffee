

myColor = '#'+(Math.random()*0xFFFFFF<<0).toString(16)

points = {}

createPoint = (id, color) ->
  $(document.body).append "<div id=\"#{id}\"> #{id} </div>"
  $("#"+id).css
    'background-color': color
    'position': 'absolute'
    'border-radius': '42px'
    'height': '84px'
    'width': '84px'

$(document).ready () ->

  $("#name").change () ->
    $("#conversation").empty()
    socket.emit 'login', "I am " + $("#name").val()

  (socket = io.connect()).on "connect", () ->
    @on 'login', (msg) -> display msg + " joined"
    @on 'players', (msg) -> display "#{p} is online" for p in msg

    # auto hosting / joining
    @on 'games', (hosted_games) =>
      if hosted_games.length == 0
        @emit 'host', { game: 'eu.andlabs.gcp.examples.points' }
      else # someone has already hosted
        @emit 'join',  hosted_games[0]
    
    # send / receive custom messages
    $(document).mousemove (e) =>
      @emit 'move',
        who: $("#name").val()
        color: myColor
        x: e.pageX-42
        y: e.pageY-42
    
    @on 'move', (msg) ->
      points[msg.who] ||= createPoint(msg.who, msg.color)
      $("#"+msg.who).css { 'left': msg.x, 'top': msg.y }

    # chat
    $("#btn-send").click () -> sendMsg()
    @on 'message', (msg) -> display(msg)

    display = (msg) ->
      $("#conversation").append('<span class="shadow">' + msg + '</span><br>')
      $("#conversation").scrollTop $("#conversation")[0].scrollHeight

    sendMsg = () ->
      display $("#name").val() + ":   " + $("#msg").val()
      socket.send $("#msg").val()
      $("#msg").val('')
    
    $('#msg').keypress (e) ->
      if e.keyCode == 13
        sendMsg()
        return false
  
  $("#name").val('')
  $("#name").focus()
   

