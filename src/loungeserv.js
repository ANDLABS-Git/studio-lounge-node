
/**
 * Copyright (C) 2013 ANDLABS. All rights reserved.
 * Author: Shawn Davies <sodxeh@gmail.com>
 *
 * This script file contains all of the main exports for the lounge server.
 * This script contains code for actually initalizing the different sockets we use and callbacks to those sockets.
 */

var exprserv = (expr = require("express"))(), sio = require("socket.io"), sioc = require("socket.io-client");

require("./router.js");

(function() {
    module.exports = {
	srv_init: function(callback) {
	    var route = new router();
	    exprserv.use(expr.bodyParser()).use(expr.static("public"))
		.set('view options', {
		    pretty: true
		}).set('view engine', 'jade').set('views', "./public/views");

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
		console.log("New connection");
		sock.on('login_req', function(data) {
		    console.log(data);
		    sock.get('username', function(error, user) {
			console.log("Login request from "+user);
		    });
		});
	    });

	},

	cl_force_bind: function() {
	    return sioc.connect("http://localhost:7777", {
		'force new connection': true
	    });
	},
    };
    
}).call(this);
