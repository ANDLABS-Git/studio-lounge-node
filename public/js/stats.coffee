$(document).ready () ->

  (socket = io.connect()).on "connect", () ->
    socket.emit 'login', "I am stat bot"
    
    @players = []
    @games = {}

    @on 'players', (players) =>
      @players = players
      $("#players").text("ONLINE: "+@players.length)
    
    @on 'login', (name) =>
      @players.push name
      $("#players").text("ONLINE: "+@players.length)

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
        $("#games").append("<h3>Host: #{game.host}</h3>
                            <ul><li>#{game.game}</li>
                              <li>Players: #{game.players}</li></ul>")
