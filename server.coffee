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
    Hosted = {}
    class Game
      constructor: (@host, msg) ->
        @id = "#{msg.game}-#{((1+Math.random())*0x1000000|0).toString(16).substring(1)}"
        Hosted[@host] = @
        Games[@id] = @
        @players = []
        @min = msg.min
        @max = msg.max
        @players.push @host
      emit: (e,m) -> IO.sockets.in(@game).emit(e,m)

    ChatConversation = []
    IO.sockets.on 'connection', (player) ->
      player.on 'login', (msg) ->
        if name = msg.match(/I am (.+)$/)?[1]
          @set 'name', name # player logged in
          @emit 'welcome', "Logged in as "+name
          #@emit 'players', OnlinePlayers 'name'
          #@emit 'games', ((g.players = g.player_cnt(); g) for h,g of Games)
          @join g.room() if g = Hosted[name]
          @send msg for msg in ChatConversation
          player.broadcast.emit 'login', name
        else
          @emit 'sorry', "Try again later"
          @disconnect 'unauthorized'
      player.on 'message', (msg) ->
        @get 'name', (err, name) -> if name
            player.broadcast.send name+":   "+msg
            ChatConversation.push {player: name, msg: msg}
      player.on 'host', (msg) ->
        @get 'name', (err, name) => if name
          game = new Game(name, msg)
          msg.game = game.id
          msg.host = name
          @join game.id
          IO.sockets.emit 'host', msg
      player.on 'state', (msg) ->
        @emit 'state', State()
      player.on 'join', (msg) ->
        @get 'name', (err, name) => if name
          game = Games[msg.game]
          if game.players.length < game.max
            game.players.push name
            @join game.id
            msg.guest = name
            IO.sockets.emit 'join', msg
            if game.players.length == game.max # full
              Hosted[game.host] = undefined
              IO.sockets.emit 'unhost', {host: game.host, game: game.id}
      player.on 'games', (msg) ->
        @emit 'games', ({game: id, players: game.players} for id, game of Games)
      player.on 'move', (msg) ->
        G(player)?.emit? 'move', msg
      player.on 'logout', (msg) ->
        @get 'name', (err, name) => if name
          IO.sockets.emit 'logout', name
    G = (socket) =>
      IO.sockets.in (room for room, obj of IO.sockets.manager.roomClients[socket.id])[1]?[1..-1]
    OnlinePlayers = (p) =>
    State = () ->
      players: for i, s of IO.sockets.sockets when s.store.data['name']
        name = s.store.data['name']
        if game = Hosted[name]
          {name: name, game: {id: game.id, min: game.min, max: game.max, joined: game.players.length}}
        else {name: name}
      chat: ChatConversation
      games_played: Object.keys(Games).length
      msges_sent: ChatConversation.length


  stop: (callback) -> IO.server.close(); callback()

  gcp: ->
    require('socket.io-client').connect "http://localhost:7777",
      { 'force new connection': true }


