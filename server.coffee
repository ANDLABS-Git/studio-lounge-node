IO = 10
module.exports =

  start: (callback) ->
     
    # express web application configuration
    @server = (express = require 'express')()
    @server.set 'views', "views"
    @server.set 'view engine', 'jade'
    @server.use express.bodyParser()
    @server.use express.static 'public'
    @server.set 'view options', { pretty: true }

    # html routes
    @server.get '/', (req, res) -> res.render 'points'
    @server.get '/points', (req, res) -> res.render 'points'
    @server.get '/stats', (req, res) -> res.render 'stats', {games: Games}

    
    # GCP messaging protocol socket.io server implementation
    IO = require('socket.io').listen @server.listen 7777, callback
    IO.set 'log level', 1
    
    Games = {}
    class Game
      constructor: (@host, @game) ->
      player_cnt: () -> IO.sockets.clients(@room()).length
      room: () -> "#{@host}-#{@game}-a23"
      emit: (e,m) -> IO.sockets.in(@room()).emit(e,m)

    ChatConversation = []
    IO.sockets.on 'connection', (player) ->
      player.on 'login', (msg) ->  # join lounge
        if name = msg.match(/I am (.+)$/)?[1]
          @set 'name', name # player logged in
          @emit 'welcome', "Logged in as "+name
          @emit 'players', OnlinePlayers 'name'
          @emit 'games', ((g.players = g.player_cnt(); g) for h,g of Games)
          @join g.room() if g = Games[name]
          @send msg for msg in ChatConversation
          player.broadcast.emit 'login', name
        else
          @emit 'sorry', "Try again later"
          @disconnect 'unauthorized'
      player.on 'message', (msg) ->
        @get 'name', (err, name) -> if name
            player.broadcast.send name+":   "+msg
            ChatConversation.push name+':   '+msg
      player.on 'host', (msg) ->
        @get 'name', (err, name) -> if name
          game = new Game(name, msg.game)
          player.join game.room()
          Games[name] = game
          msg.host = name
          msg.players = game.player_cnt()
          player.broadcast.emit 'host', msg
      player.on 'state', (msg) ->
        @emit State()
      player.on 'join', (msg) ->
        @get 'name', (err, name) -> if name
          game = Games[msg.host]
          player.join game.room()
          player.broadcast.emit 'join', {guest: name, game: game.game}
      player.on "move", (msg) ->
        G(player)?.emit? 'move', msg
    G = (socket) =>
      IO.sockets.in (room for room, obj of IO.sockets.manager.roomClients[socket.id])[1]?[1..-1]
    OnlinePlayers = (p) =>
      s.store.data[p] for i, s of IO.sockets.sockets when s.store.data[p]
    State = () ->
      ({player: player, games: games} for player, games of Games)


  stop: (callback) -> IO.server.close(); callback()

  gcp: ->
    require('socket.io-client').connect "http://localhost:7777",
      { 'force new connection': true }


