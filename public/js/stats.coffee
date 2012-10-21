$(document).ready () ->

  (socket = io.connect()).on "connect", () ->
    socket.emit 'login', "I am stat bot"
    
    @players = 0
    @games = {}

    @on 'players', (players) =>
      @players = players.length
      $("#players").text("ONLINE: "+@players)
    
    @on 'login', (msg) ->
      @players += 1
      $("#players").text("ONLINE: "+@players)

    @on 'games', (games) =>
      @games[g.host] = g for g in games
      display()

    @on 'host', (game) =>
      @games[game.host] = game
      display()

    @on 'join', (msg) =>
      @games[msg.host].players += 1
      display()

    display = () =>
      $("#games").empty()
      for h,game of @games
        $("#games").append("<h3>#{game.host}</h3>
                            <ul><li>Host: #{game.game}</li>
                              <li>Players: #{game.players}</li></ul>")
