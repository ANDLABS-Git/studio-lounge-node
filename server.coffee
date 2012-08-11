server = (express = require 'express')()

# Configuration
server.set 'views', "views"
server.use express.bodyParser()
server.set 'view engine', 'jade'
server.use express.static 'public'
server.set 'view options', { pretty: true }

# Routes
server.get '/', (req, res) -> res.render 'index', {title: "hAppy Log"}

server.listen 8080
