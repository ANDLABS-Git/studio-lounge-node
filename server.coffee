
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
    
    ChatConversation = []
    @io.sockets.on 'connection', (player) ->
      player.on 'Hi', (msg) ->  # join lounge
        if name = msg.match(/I am (.+)$/)?[1]
          @set 'name', name # player logged in
          @emit 'Welcome', "Logged in as "+name
          @send msg for msg in ChatConversation
          player.broadcast.emit 'Joining', name
        else
          @emit 'Sorry', "Try again later..."
          @disconnect 'unauthorized'
      player.on 'message', (msg) ->
        @get 'name', (err, name) ->
          player.broadcast.send name+":   "+msg
          ChatConversation.push name+':   '+msg
    
    @io.set 'log level', 1


  stop: (callback) -> @io.server.close(); callback()

  game: ->
    require('socket.io-client').connect "http://localhost:7777",
      { 'force new connection': true }


