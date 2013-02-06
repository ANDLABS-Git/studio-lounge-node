server = require '../server'
expect = require('chai').expect
io = require 'socket.io-client'
BeginOfTest = 0
InBetween = 0
GravityMatchId = ''
MoleculeMatchId = ''
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
      @lukas.emit 'chat', "happy again :-)"
      @anyplayer.on 'chat', (msg) ->
        expect(msg).to.deep.equal {
          player: "Lukas",
          text: "happy again :-)"
        }
        History += 1
      @anotherplayer.on 'message', (msg) ->
        expect(msg).to.deep.equal {
          player: "Lukas",
          text: "happy again :-)"
        }
        done()
 
    it "must not let players chat who are not logged in", (done) ->
      server.gcp().on 'connect', () ->
        @emit 'chat', "I did not log in but I chat anayway"
      @lukas.on 'chat', (msg) -> expect(true).to.be.not.ok
      setTimeout done, 100 #ms





  describe "GAME APPublishing", () ->

    xit "should let the server publish game apps", (done) ->
      server.post { game: "new.game", name: "FunnyFoo" }
      @lukas.on 'publish', (game) ->
        expect(game).to.deep.equal {
          game: "new.game",
          name: "FunnyFoo"
        }
        done()





  describe "MATCH MAKING (players <-> games)", () ->

    InBetween = Date.now()

    it "should allow any logged in player to host games", (done) ->
      @anyplayer.emit 'host', { game: "de.gravity", max: 3 }
      @anyplayer.on 'host', (match) -> # host gets it too
        GravityMatchId = match.id # server assigned GUID
        expect(match.game).to.equal "de.gravity"
        expect(match.host).to.equal "Anyname"
        expect(match.max).to.equal 3
        expect(match.id).to.be.ok
        History += 1
      @lukas.on 'host', (match) ->
        expect(match.game).to.equal "de.gravity"
        expect(match.host).to.equal "Anyname"
        expect(match.max).to.equal 3
        expect(match.id).to.be.ok
        done()
      @lukas.emit 'host', { game: "de.mole", max: 3 }
      @anotherplayer.on 'host', (match) ->
        MoleculeMatchId = match.id

    it "should deny anyone else to host a new game", (done) ->
      @troll.emit 'host', { game: "a.random.game", min: 43, max: 55 }
      @anotherplayer.on 'host', (msg) -> expect("that").to.be.not.ok
      setTimeout done, 58
 
    it "should broadcast that another player joins", (done) ->
      @anotherplayer.emit 'join', { match: GravityMatchId }
      @anyplayer.on 'join', (msg) =>
        expect(msg.player).to.equal "Ananda"
        expect(msg.match).to.equal GravityMatchId
        History += 1
        done()
      @anyplayer.emit 'join', { match: MoleculeMatchId }





  describe "CUSTOM MESSAGING", () ->

    it "should broadcast game messages among players of a match", (done) ->
      @anyplayer.emit 'msg', {
        foo: "my", data: 42,
        match: GravityMatchId
        persist: 1
      }
      @anotherplayer.on 'msg', (msg) =>
        expect(msg).to.deep.equal {
          foo: "my", data: 42,
          match: GravityMatchId,
          sender: "Anyname",
          next: "Ananda",
          persist: 1
        }
        History += 1
        done()





  describe "CHECKING IN AND OUT", () ->

    it "should let player check into the lobby", (done) ->
      @lukas.emit 'checkin', "lobby-xy"
      @anyplayer.on 'checkin', (status) ->
        expect(status.player).to.equal "Lukas"
        expect(status.match).to.equal "lobby-xy"
      # status updates only for matched players
      @anotherplayer.on 'checkin', (status) ->
        expect("this").to.be.not.ok
      setTimeout done, 99 # ms





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
