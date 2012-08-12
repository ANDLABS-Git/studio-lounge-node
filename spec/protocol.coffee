server = require '../server'
expect = require('chai').expect
io = require 'socket.io-client'


#   GCP PROTOCOL SPECIFICATION   *StudioLounge Multiplayer Game*
#                         v0.1                           (Final)
#   (in)formal description of digital message formats and rules, 
#   for exchanging of theese messages between computing systems,
#   defines syntax, semantics, synchronization of communication;
#   the specified behavior is independent of how it implemented.
#                                             ~~ wikipedia  ###

describe "Game COMMUNICATIONS PROTOCOL Specification v0.1 \n", ->

  before (test) -> server.start test
  
  it "should make developers smile", -> expect(":-)").to.be.ok
 

  describe "Login", ->

    it "should allow any player to login with anyname", (done) ->
      (@anyplayer = server.game()).on "connect", () ->
        @emit 'Hi', "I am Anyname"
        @on 'Welcome', (msg) ->
          expect(msg).to.equal "Logged in as Anyname"
          done()
  
    it "should deny anyone else who does a wrong login", (done) ->
      @troll = server.game().on "connect", () ->
        @emit 'Hi', "I say sth studid"
        @on 'Sorry', (excuse) ->
          expect(excuse).to.equal "Try again later..."
          done()
   
   

  describe "Chat", ->

    it "should let lukas post *happy* progress* logs", (done) ->
      (@lukas = server.game()).on "connect", () ->
        @emit 'Hi', "I am Lukas"
        @on 'Welcome', (msg) ->
          @emit "I am happy today :-)"
          done()
  
     it "should notify avout players joining the lobby", (done) ->
      (@anotherplayer = server.game()).on "connect", () ->
        @emit 'Hi', "I am Ananda"
      notified_players = 0
      @anyplayer.on 'Joining', (msg) ->
        notified_players += 1
        expect(msg).to.equal "Ananda"
      @lukas.on 'Joining', (msg) ->
        notified_players += 1
        expect(msg).to.equal "Ananda"
      @troll.on 'Joining', (msg) -> expect(true).to.not.be.ok
      setTimeout ( () ->
        expect(notified_players).to.equal 2 ; done() ), 1500
   
    it "should multiplex happy logs to other players", (done) ->
      @lukas.send "happy again :-)"
      @anyplayer.on 'message', (msg) ->
        expect(msg).to.equal "Lukas:   happy again :-)"
      @anotherplayer.on 'message', (msg) ->
        expect(msg).to.equal "Lukas:   happy again :-)"
        done()


# it "should allow players to send private messages", (done) ->

# it "should bring multiple game players together ", (done) ->

# it "should empower players to plant happy* trees", (done) ->

  after (test) -> server.stop test

