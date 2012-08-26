server = require '../server'
expect = require('chai').expect
sinon = require 'sinon'
io = require 'socket.io-client'


#   GCP PROTOCOL SPECIFICATION   *StudioLounge Multiplayer Game*
#                         v0.2    RFC                    (Draft)
#   (in)formal description of digital message formats and rules, 
#   for exchanging of theese messages between computing systems,
#   defines syntax, semantics, synchronization of communication;
#   the specified behavior is independent of how it implemented.
#                                             ~~ wikipedia  ###

describe "Game COMMUNICATIONS PROTOCOL Specification v0.2 \n", ->

  before (test) -> server.start test
  
  it "should make developers smile", -> expect(":-)").to.be.ok

  describe "LOGIN", ->

    it "should allow any player to login with any name", (done) ->
      (@anyplayer = server.gcp()).on "connect", () ->
        @emit 'login', "I am Anyname"
        @on 'welcome', (msg) ->
          expect(msg).to.equal "Logged in as Anyname"
          done()
  
    it "should deny anyone else who does a wrong login", (done) ->
      (@troll = server.gcp()).on "connect", () ->
        @emit 'login', "I do it wrong ;-P"
        @on 'sorry', (msg) ->
          expect(msg).to.equal "Try again later"
          done()
 
    it "must inform about players that are already online", (done) ->
      (@anotherplayer = server.gcp()).on "connect", () ->
        @emit 'login', "I am Ananda"
        @on 'players', (msg) ->
          expect(msg).to.deep.equal ["Anyname", "Ananda"]
          done()

    it "should notify about players joining the lobby", (done) ->
      (@lukas = server.gcp()).on "connect", () ->
        @emit 'login', "I am Lukas"
      @anyplayer.on 'login', (msg) => this.happens()
      @anotherplayer.on 'login', (msg) => this.happens()
      @troll.on 'login', (msg) -> expect("this").to.not.be.ok
      setTimeout ( () =>
        expect(@happens.calledTwice).to.be.ok
        done() ), 21 # ms responsiveness !!!
  
   

  describe "CHAT", ->

    it "must multiplex chat msgs to all other players", (done) ->
      @lukas.send "happy again :-)"
      @anyplayer.on 'message', (msg) ->
        expect(msg).to.equal "Lukas:   happy again :-)"
      @anotherplayer.on 'message', (msg) ->
        expect(msg).to.equal "Lukas:   happy again :-)"
        done()

    it "must not let players chat who are not logged in", (done) ->
      server.gcp().on 'connect', () ->
        @send "I did not log in but I chat anayway"
      @lukas.on 'message', (msg) -> expect(true).to.be.not.ok
      setTimeout done, 123


  describe "Host Game (5-way) Handshake", () ->

    it "must inform all players about a new hosted game", (done) ->
      @lukas.emit 'host', { game: "a.sample.game"}
      @anyplayer.on 'host', (msg) ->
        expect(msg.game).to.equal "a.sample.game"
        expect(msg.host).to.equal "Lukas"
        done()

    it "should tell the host if anyplayer wants to join", (done) ->
      @anyplayer.emit 'join', { host: "Lukas" }
      @lukas.on 'join', (msg) ->
        this.happens()
        expect(msg.guest).to.equal "Anyname"
      @anotherplayer.on 'join', (msg) -> expect("this").to.not.exist
      setTimeout ( () =>
        expect(@happens.calledOnce).to.be.ok
        done() ), 123 # ms

    it "should confirm that the host accepted the join", (done) ->
      @lukas.emit 'confirm', "Anyname"
      @anyplayer.on 'confirm', (msg) ->
        expect(msg).to.equal "Lukas"
        done()

    it "must start the game when all apps are initialized", (done) ->
      @anyplayer.emit 'ready', { game: "a.sample.game" }
      @lukas.emit 'ready', { game: "a.sample.game" }
      @lukas.on 'start', (msg) -> this.happens()
      @anyplayer.on 'start', (msg) -> this.happens()
      setTimeout ( () =>
        expect(@happens.calledTwice).to.be.ok
        done() ), 21 # ms responsiveness !!!


  describe "Game Moves", () ->

    it "should send and receive custom game move messages", (done) ->
      @anyplayer.emit 'move', {abc: "my", data: 42}
      @lukas.on 'move', (msg) ->
        expect(msg.abc).to.equal "my"
        expect(msg.data).to.equal 42
        this.happens()
      @anotherplayer.on 'move', (msg) -> expect("this").to.not.exist
      setTimeout ( () =>
        expect(@happens.calledOnce).to.be.ok
        done() ), 123 # ms





# it "should allow players to send private messages", (done) ->

# it "should bring multiple game players together ", (done) ->

# it "should empower players to plant happy* trees", (done) ->

  after (test) -> server.stop test

  beforeEach () -> @happens = sinon.spy()
