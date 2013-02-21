
/**
 * Copyright (C) 2013 ANDLABS. All rights reserved.
 * Author: Shawn Davies <sodxeh@gmail.com>
 *
 * This script file contains all of the main exports for the lounge server.
 * This script contains code for actually initalizing the different sockets we use and callbacks to those sockets.
 */


/**
 * Dependent packages from node.js package manager.
 */
var exprserv = (expr = require("express"))(), sio = require("socket.io"), sioc = require("socket.io-client");

/**
 * We require this router class to perform all http rerouting.
 * This router script may become deprecated in the future, depending on where we decide
 * to go with the design of this server architecture.
 */
require("./router.js");

/**
 * The array of connected sessions, sorted by a key type of 'socket'.
 */
var sessions = [];

/**
 * A simple representation of a connected client. This will probably be built upon in the near future.
 */
function Session(username, password, socket) {
    this.username = username;
    this.password = password;
    this.socket = socket;
}

/**
 * Various prototypes for any given session.
 */
Session.prototype = {
    join: function(name) {
	this.room = name;
	this.socket.join(name);
	this.socket.broadcast.to(name).emit('chat_append', 'Master Lounge', this.username+' has connected to the '+name+' chat room.');
    },
};

/**
 * The exports of this server script. This is what is included in require('loungeserv.js').
 */
module.exports = {
    srv_init: function(callback) { 
	var route = new router();
	exprserv.use(expr.bodyParser()).use(expr.static("public"))
	    .set('view options', {
		pretty: true
	    });

	var listener = sio.listen(exprserv.listen(7777, callback)).set('log level', 1);

	exprserv.get('/', function(request, result) {// Requesting root
	    if (request.route.method == 'get') {// It's requesting a page, so let's simply give the client our index page for now.
		// Later we can add support here for rerouting of the client's location depending on current lounge location.
		var post = route.post_file(result, request, "index.html");//route.post_render(result, 'index');
		if (post != null) {
		    return post;
		}
	    }
	});

	listener.sockets.on('connection', function(sock) {

	    sock.on('provide_login', function(user, pass) {
		if (sessions[user] != null) {
		    return;// user is already logged in (probably?).
		}
		
		var session = sessions[sock] = new Session(user, pass, sock);
		session.join('main');
		sock.emit('response_login', 0);//0 = successful login, 1 = wrong password, other = ??

		console.log('\nSession info:');
		console.log(session);
	    });

	    sock.on('disconnect', function() {
		listener.emit('chat_append', 'Master Lounge', 'User disconnected.');// emit to all connected clients that the user has disconnected.
		//TODO Add reasoning behind disconnection, as well as print socket name and so on.

		sock.leave(sock.room);
		delete sessions[sock];

		console.log("Socket disconnected.");
	    });
	});
    },

};
