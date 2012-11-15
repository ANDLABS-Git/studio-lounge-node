server = require '../server'
expect = require('chai').expect
sinon = require 'sinon'
io = require 'socket.io-client'
GameInstanceID = ""

#   GCP PROTOCOL SPECIFICATION   *StudioLounge Multiplayer Game*
#                         v0.3                           (final)
#   (in)formal description of digital message formats and rules, 
#   for exchanging of theese messages between computing systems,
#   defines syntax, semantics, synchronization of communication;
#   the specified behavior is independent of how it implemented.
#                                             ~~ wikipedia  ###

describe "Game COMMUNICATIONS PROTOCOL Specification v0.3 \n", ->

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

    it "should notify everyone about players that log in", (done) ->
      (@anotherplayer = server.gcp()).on "connect", () -> @emit 'login', "I am Ananda"
      (@lukas = server.gcp()).on "connect", () -> @emit 'login', "I am Lukas"
      @anyplayer.on 'login', (msg) => this.happens()
      @troll.on 'login', (msg) -> expect("this").to.not.be.ok
      setTimeout ( () =>
        expect(@happens.calledTwice).to.be.ok
        done() ), 21 # ms responsiveness !!!  



  describe "CHATTING", ->

    it "must multiplex up to 42 existing chat msgs", (done) ->
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

    it "should allow any logged in player to host games", (done) ->
      @anyplayer.emit 'host', { game: "my.game", min: 2, max: 3}
      @lukas.on 'host', (msg) ->
        expect(msg.game).to.match /my\.game-.+/
        expect(msg.host).to.equal "Anyname"
        expect(msg.min).to.equal 2
        expect(msg.max).to.equal 3
      @anyplayer.on 'host', (msg) ->   # host gets the msg too 
        expect(msg.game).to.match /my\.game-.+/
        expect(msg.host).to.equal "Anyname"
        expect(msg.min).to.equal 2
        expect(msg.max).to.equal 3
        GameInstanceID = msg.game
        done()

    it "should deny anyone else to host a new game", (done) ->
      @troll.emit 'host', { game: "a.random.game"}
      @anotherplayer.on 'host', (msg) -> expect("that").to.be.not.ok
      setTimeout done, 58
 
    it "should inform about everything upon request", (done) ->
      @lukas.send 'state'
      @lukas.on 'state', (msg) ->
        expect(msg).to.deep.equal( {
          players: [
            {
              player:  "Anyname"
              games: [
                {
                  game: GameInstanceID
                  joined:  1
                  min:     2
                  max:     3
                }
              ]
            },
            { player: "Lukas" },
            { player: "Ananda"  }
          ],
          chat: [ { player: "Lukas", msg: "happy again :-)" } ],
          games_played: 0,
          msges_send: 42
        })

    it "should tell all players when another player joins", (done) ->
      @anotherplayer.emit 'join', { game: @anyplayer.gameInstanceID }
      @lukas.emit 'join', { game: @anyplayer.gameInstanceID }
      @anotherplayer.on 'join', (msg) =>
        this.happens()
        expect(msg.game).to.equal GameInstanceID
      @anyplayer.on 'join', (msg) =>
        this.happens()
        expect(msg.game).to.equal GameInstanceID
      setTimeout ( () =>
        expect(@happens.calledTwice).to.be.ok
        done() ), 42 # ms responsiveness !!!

    it "should alow a server to unhost games (e.g. when full)" , (done) ->
      @lukas.emit 'join', { game: @anyplayer.gameInstanceID }
      @anyplayer.on "unhost", (msg) =>
        this.happens()
        expect(msg.host).to.equal "Anyname"
        expect(msg.game).to.equal GameInstanceID
      @anotherplayer.on "unhost", (msg) =>
        this.happens()
        expect(msg.host).to.equal "Anyname"
        expect(msg.game).to.equal GameInstanceID



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



  describe "LOGOUT", () ->

    it "should notify about players that log out", (done) ->
      @anyplayer.send 'logout'
      @anotherplayer.on 'logout', (msg) ->
        expect(msg).to.equal "Anyname"
        done()




# it "should allow players to send private messages", (done) ->

# it "should bring multiple game players together ", (done) ->

# it "should empower players to plant happy* trees", (done) ->

  after (test) -> server.stop test

  beforeEach () -> @happens = sinon.spy()
