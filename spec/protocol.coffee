server = require '../server'
expect = require('chai').expect
io = require 'socket.io-client'


###  PROTOCOL SPECIFICATION  *StudioLounge Multiplayer Game*
                                           RFC 0.0.1 (Draft)
(in)formal description of digital message formats and rules, 
for exchanging of theese messages between computing systems,
defines syntax, semantics, synchronization of communication;
the specified behavior is independent of how it implemented.
                                           ~~ wikipedia  ###

describe "Game COMMUNICATIONS PROTOCOL Specification v0.1", ->

  before (test) -> server.start test
  
  xit "should make players smile", -> expect(":-)").to.be.ok
  
  it "should allow any player to login with anyname", (done) ->
    (@anyplayer = server.game()).on "connect", () ->
      @emit 'Hi', "I am Anyname"
      @on 'Welcome', (msg) ->
        expect(msg).to.equal 'Logged in as Anyname'
        done()
  
  it "should deny anyone else who is bit unfriendly", (done) ->
    @troll = server.game().on "connect", () ->
      @emit 'Hi', "Me too want!!!"
      @on 'Sorry', (excuse) ->
        expect(excuse).to.equal 'Kommst nicht rein'
        done()
        
  it "should let lukas post *happy* progress* logs", (done) ->
    (@lukas = server.game()).on "connect", () ->
      @emit 'Hi', "I am Lukas"
      @on 'Welcome', (msg) ->
        @emit "I am happy today :-)"
        done()

  it "should multiplex happy logs to other players", (done) ->
    @lukas.send "happy again :-)"
    @anyplayer.on 'message', (msg) ->
      expect(msg).to.equal "Lukas:   happy again :-)"
    @anotherplayer = server.game().on "connect", () ->
      @emit 'Hi', "I am Ananda"
      @on 'message', (msg) ->
        expect(msg).to.equal "Lukas:   happy again :-)"
        done()


# it "should bring multiple game players together ", (done) ->

# it "should empower players to plant happy* trees", (done) ->

  after (test) -> server.stop test

