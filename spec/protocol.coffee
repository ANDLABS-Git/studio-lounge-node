server = require '../server'
expect = require('chai').expect
io = require 'socket.io-client'
BeginOfTest = 0
InBetween = 0
MatchId = ""
History = 0

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
        History += 1
      @anotherplayer.on 'message', (msg) ->
        expect(msg).to.equal "Lukas:   happy again :-)"
        done()
 
    it "must not let players chat who are not logged in", (done) ->
      server.gcp().on 'connect', () ->
        @send "I did not log in but I chat anayway"
      @lukas.on 'message', (msg) -> expect(true).to.be.not.ok
      setTimeout done, 58





  describe "MATCHING (players with games)", () ->

    InBetween = Date.now()

    it "should allow any logged in player to host games", (done) ->
      @anyplayer.emit 'host', { game: "my.game", min: 2, max: 3}
      @anyplayer.on 'host', (match) -> # host gets it too
        expect(match.host).to.equal "Anyname"
        expect(match.min).to.equal 2
        expect(match.max).to.equal 3
        MatchId = match.id # server assigned GUID
        History += 1
      @lukas.on 'host', (match) ->
        expect(match.host).to.equal "Anyname"
        expect(match.min).to.equal 2
        expect(match.max).to.equal 3
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
        History += 1
        done()

  
  


  describe "CUSTOM MESSAGING", () ->

    it "should broadcast game messages among players of a match", (done) ->
      @anotherplayer.emit 'move', { foo: "my", data: 42 }
      @anyplayer.on 'move', (msg) =>
        expect(msg).to.deep.equal( { foo: "my", data: 42 }
        History += 1
        done()





  describe "HISTORY (catch up)", ->

    replay = History
    
    it "should tell no diff if nothing happened", (done) ->
      @anyplayer.emit 'history', { since: Date.now }
      setTimeout ( () ->
        expect(History).to.equal replay # still the same
        ), 333 #ms

    it "should tell the difference if something happened in between", (done) ->
      History = 0
      @anyplayer.emit 'history', { since: InBetween }
      setTimeout ( () ->
        expect(History).to.equal 3   # [host, join, move] have been replayed 
        ), 55 #ms

    it "should tell the difference of everything that ever happened", (done) ->
      History = 0
      @anyplayer.emit 'history', { since: BeginOfTest }
      setTimeout ( () ->
        expect(History).to.equal replay
        ), 55 #ms

 





# it "should allow players to send private messages", (done) ->
# it "should bring multiple game players together ", (done) ->
# it "should empower players to plant happy* trees", (done) ->

  after (test) -> server.stop test

  beforeEach () -> @happens = sinon.spy()
