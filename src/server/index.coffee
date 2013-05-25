http = require 'http'
express = require 'express'
coffeeify = require 'coffeeify'
gzippo = require 'gzippo'
derby = require 'derby'
#app = require '../app'
inlet = require '../inlet'
serverError = require './serverError'

expressApp = express()
server = http.createServer(expressApp)

module.exports = server

# The store creates models and syncs data
store = derby.createStore
  server: server
  db: derby.db.mongo 'localhost:27017/derby-sink?auto_reconnect', {safe: true}

store
  .use(require 'racer-browserchannel')

ONE_YEAR = 1000 * 60 * 60 * 24 * 365
mount = '/inlet'
publicDir = require('path').join __dirname + '/../../public'

#derby
#  .set('staticMount', mount)

store.on 'bundle', (browserify) ->
  browserify.add publicDir + '/jquery-1.9.1.min.js'
  # Add support for directly requiring coffeescript in browserify bundles
  browserify.transform coffeeify

ipMiddleware = (req, res, next) ->
  forwarded = req.header 'x-forwarded-for'
  ipAddress = forwarded && forwarded.split(',')[0] ||
    req.connection.remoteAddress

  model = req.getModel()
  model.set '_info.ipAddress', ipAddress
  next()

expressApp
  .use(express.favicon())
  
  .use(mount, gzippo.staticGzip publicDir, maxAge: ONE_YEAR)
  # Gzip dynamically rendered content
  .use(express.compress())
  .use(inlet.scripts(store))

  # Respond to requests for application script bundles
  # racer-browserchannel adds a middleware to the store for responding to
  # requests from remote models
  .use(store.socketMiddleware())

  # Adds req.getModel method
  .use(store.modelMiddleware())

  .use(ipMiddleware)

  # Creates an express middleware from the app's routes
  .use(inlet.router())
  .use(expressApp.router)
  .use(serverError())

expressApp.all '*', (req, res, next) ->
  next '404: ' + req.url
