server = require '../server'
expect = require('chai').expect
sinon = require 'sinon'
io = require 'socket.io-client'


#   GCP PROTOCOL SPECIFICATION   *StudioLounge Multiplayer Game*
#                         v0.3    RFC                    (Draft)
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



  describe "CHATTING", ->

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
      setTimeout done, 58



  describe "HOSTING GAMES", () ->

    it "should allow any logged in player to host a game", (done) ->
      @anyplayer.emit 'host', { game: "my.game"}
      @lukas.on 'host', (msg) ->
        expect(msg.game).to.equal "my.game"
        expect(msg.host).to.equal "Anyname"
        done()

    it "should deny anyone else to host a new game", (done) ->
      @troll.emit 'host', { game: "a.random.game"}
      @anotherplayer.on 'host', (msg) -> expect("that").to.be.not.ok
      setTimeout done, 58
 
    it "must inform about open hosted games that are already online", (done) ->
      (@yetanotherplayer = server.gcp()).on "connect", () ->
        @emit 'login', "I am Yet Another new Player"
        @on 'games', (msg) ->
          expect(msg[0].game).to.deep.equal "my.game"
          expect(msg[0].host).to.deep.equal "Anyname"
          done()

    it "should tell any host what other players want to join", (done) ->
      @anotherplayer.emit 'join', { host: "Anyname", game: "my.game" }
      @lukas.emit 'join', { host: "Anyname", game: "my.game" }
      @anyplayer.on 'join', (msg) => this.happens()
      setTimeout ( () =>
        expect(@happens.calledTwice).to.be.ok
        done() ), 42 # ms responsiveness !!!

    it "should acknowledge to all participants that the game starts", (done) ->
      @anyplayer.emit 'start', { host: "Anyname", game: "my.game" }
      @anotherplayer.on 'start', (msg) => this.happens()
      @lukas.on 'start', (msg) => this.happens()
      setTimeout ( () =>
        expect(@happens.calledTwice).to.be.ok
        done() ), 42 # ms responsiveness !!!



  describe "CUSTOM MESSAGING", () ->

    it "should send custom game move messages to everyone in the game", (done) ->
      @anyplayer.emit 'move', {abc: "my", data: 42}
      @lukas.on 'move', (msg) => this.happens()
      @anotherplayer.on 'move', (msg) =>
        expect(msg.abc).to.equal "my"
        expect(msg.data).to.equal 42
        this.happens()
      @yetanotherplayer.on 'move', (msg) -> expect("this").to.not.exist
      setTimeout ( () =>
        expect(@happens.calledTwice).to.be.ok
        done() ), 42 # ms





# it "should allow players to send private messages", (done) ->

# it "should bring multiple game players together ", (done) ->

# it "should empower players to plant happy* trees", (done) ->

  after (test) -> server.stop test

  beforeEach () -> @happens = sinon.spy()
