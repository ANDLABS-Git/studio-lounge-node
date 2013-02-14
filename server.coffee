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

    
    # GCP messaging protocol socket.io server implementation
    IO = require('socket.io').listen @server.listen 7777, callback
    IO.set 'log level', 1
    History = []
    
    IO.sockets.on 'connection', (player) ->
      player.on 'login', (msg) ->
        if name = msg.match(/I am (.+)$/)?[1]
          @set 'name', name # player logged in
          @emit 'welcome', "Logged in as "+name
        else
          @emit 'sorry', "Try again later"
          @disconnect 'unauthorized'
      player.on 'chat', (text) ->
        @get 'name', (err, name) -> if name
          msg = { text: text, sender: name }
          IO.sockets.emit 'chat', msg
          History.push { what: 'chat', msg: msg }
      player.on 'host', (match) ->
        @get 'name', (err, name) => if name
          match.id = RandomGUID()
          match.host = name
          @join match.id
          IO.sockets.emit 'host', match
          History.push { what: 'host', msg: match }
      player.on 'join', (match) ->
        @get 'name', (err, name) => if name
          @join match.id
          match.player = name
          IO.sockets.emit 'join', match
          History.push { what: 'join', msg: match }
      player.on 'msg', (msg) ->
        @get 'name', (err, name) => if name
          msg.sender = name
          msg.next = SelectNext(msg.match, name)
          IO.sockets.in(msg.match).emit 'msg', msg
          History.push { what: 'msg', msg: msg }
      player.on 'history', (msg) ->
        @emit m.what, m.msg for m in History
      player.on 'logout', (msg) ->
        console.log "logout"
    
    RandomGUID = () -> ((1+Math.random())*0x1000000|0).toString(16).substring(1)
    SelectNext = (match, activePlayer) -> (n for n in (s.store.data.name for s in IO.sockets.clients(match)) when n != activePlayer)[0]

  stop: (callback) -> IO.server.close(); callback()

  gcp: ->
    require('socket.io-client').connect "http://localhost:7777",
      { 'force new connection': true }


