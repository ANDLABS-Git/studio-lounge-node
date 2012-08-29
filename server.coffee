
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
    @server.get '/', (req, res) -> res.render 'index'

    
    # GCP messaging protocol socket.io server implementation
    @io = require('socket.io').listen @server.listen 7777, callback
    @io.set 'log level', 1
    
    ChatConversation = []
    @io.sockets.on 'connection', (player) ->
      player.on 'login', (msg) ->  # join lounge
        if name = msg.match(/I am (.+)$/)?[1]
          @set 'name', name # player logged in
          @emit 'welcome', "Logged in as "+name
          @emit 'players', OnlinePlayers 'name'
          @emit 'games', OpenHostedGames 'name'
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
#          player.set 'game', msg.game
          player.join "#{name}-#{msg.game}"
          msg.host = name
          player.broadcast.emit 'host', msg
      player.on 'join', (msg) ->
        @get 'name', (err, name) -> if name
          Game(msg).emit 'join', {guest: name}
          player.join "#{msg.host}-#{msg.game}"
      player.on 'start', (msg) ->
        @get 'name', (err, name) -> if name
          Game(msg).emit 'start'
      player.on "move", (msg) ->
        G(player).emit 'move', msg
    G = (socket) =>
      @io.sockets.in (room for room, obj of @io.sockets.manager.roomClients[socket.id])[1][1..-1]
    Game = (msg) =>
      @io.sockets.in "#{msg.host}-#{msg.game}"
    OnlinePlayers = (p) =>
      s.store.data[p] for i, s of @io.sockets.sockets
    OpenHostedGames = (p) =>
      #console.log require("util").inspect(@io.sockets.manager)
      (for room, players of @io.sockets.manager.rooms when room != ''
        #host = @io.sockets.sockets[players[0]].store.data[p]
        [host, game] = room[1..-1].split "-"
        { game: game, host: host })
   


  stop: (callback) -> @io.server.close(); callback()

  gcp: ->
    require('socket.io-client').connect "http://localhost:7777",
      { 'force new connection': true }


