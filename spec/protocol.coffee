server = require '../server'
expect = require('chai').expect
sinon = require 'sinon'
io = require 'socket.io-client'
BeginOfTest = 0
MatchId = ""

#   GCP PROTOCOL SPECIFICATION   *StudioLounge Multiplayer Game*
#                         v0.4                           (draft)
#   (in)formal description of digital message formats and rules, 
#   for exchanging of theese messages between computing systems,
#   defines syntax, semantics, synchronization of communication;
#   the specified behavior is independent of how it implemented.
#                                             ~~ wikipedia  ###

describe "Game COMMUNICATIONS PROTOCOL Specification v0.3 \n", ->

  before (test) -> server.start test
  
  it "should make developers smile", -> expect(":-)").to.be.ok





  describe "LOGIN", ->

    BeginOfTest = Date.now

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





  describe "CHATTING", ->

    (@anotherplayer = server.gcp()).on "connect", () -> @emit 'login', "I am Ananda"
    (@lukas = server.gcp()).on "connect", () -> @emit 'login', "I am Lukas"

    it "should allow players to chat in the public chatroom", (done) ->
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





  describe "MATCHING (players with instances of games)", () ->

    it "should allow any logged in player to host games", (done) ->
      @anyplayer.emit 'host', { game: "my.game", min: 2, max: 3}
      @lukas.on 'host', (match) ->
        expect(match.host).to.equal "Anyname"
        expect(match.min).to.equal 2
        expect(match.max).to.equal 3
        MatchId = match.id
        done()

    it "should deny anyone else to host a new game", (done) ->
      @troll.emit 'host', { game: "a.random.game", min: 43, max: 55 }
      @anotherplayer.on 'host', (msg) -> expect("that").to.be.not.ok
      setTimeout done, 58
 
    it "should broadcast that another player joins", (done) ->
      @anotherplayer.on 'join', (msg) =>
      @anyplayer.on 'join', (msg) =>
        expect(msg.player).to.equal "Ananda"
        expect(msg.id).to.equal MatchId
        done()

  
  


  describe "HISTORY (catch up)", ->

    it "should tell (the diff) what happened in some meanwhile", (done) ->
      @anyplayer.emit 'history', { since: Date.now }
      @anyplayer.on 'history', (diffs) ->
        expect(diffs).to.deep.equal( {
          players: [],
          games: [],
          match: [],
          chat: []
          stats: { player_online: 3, games_played: 1}
        } # not much happened since now :-)
    
      @anyplayer.emit 'history', { since: BeginOfTest }
      @anyplayer.on 'history', (diffs) ->
        expect(diffs).to.deep.equal( {
          players: [],
          games: [],
          match: [ {
            id: MatchID
            min: 2
            max: 3
            host: "Anyname"
            players: ["Ananda"]
            } ],
          chat: ["Lukas:   happy again :-)"]
          stats: { player_online: 3, games_played: 1}
        }
 
 



  describe "CUSTOM MESSAGING", () ->

    it "should send custom game messages to everyone in the game", (done) ->
      @anyplayer.emit 'move', {foo: "my", data: 42}
      @anotherplayer.on 'move', (msg) =>
        expect(msg).to.deep.equal( {
          foo: "my"
          data: 42
        }







# it "should allow players to send private messages", (done) ->
# it "should bring multiple game players together ", (done) ->
# it "should empower players to plant happy* trees", (done) ->

  after (test) -> server.stop test

  beforeEach () -> @happens = sinon.spy()
