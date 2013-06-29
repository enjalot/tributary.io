http = require 'http'
express = require 'express'
MongoStore = require('connect-mongo')(express)
coffeeify = require 'coffeeify'
gzippo = require 'gzippo'
derby = require 'derby'
#livedb stuff
racerBrowserChannel = require 'racer-browserchannel'
liveDbMongo = require 'livedb-mongo'
createLoggerStream = require './logger'

everyauth = require('everyauth')
conf = require('./conf')

app = require '../app'
serverError = require './serverError'

expressApp = express()
server = http.createServer(expressApp)

module.exports = server

ONE_YEAR = 1000 * 60 * 60 * 24 * 365
mount = '/inlet'
publicDir = require('path').join __dirname + '/../../public'


# The store creates models and syncs data
if process.env.OPENREDIS_URL
  redisUrl = require('url').parse process.env.OPENREDIS_URL
  redis = require('redis').createClient redisUrl.port, redisUrl.hostname
  redis.auth(redisUrl.auth.split(":")[1])
else
  redis = require('redis').createClient()
redis.select 4

mongoUri = process.env.MONGOHQ_URL || 'mongodb://localhost:27017/tributary-io'

loggerStream = createLoggerStream()
loggerStream.pipe(process.stdout)
store = derby.createStore
  db: liveDbMongo(mongoUri + '?auto_reconnect', safe: true)
  redis: redis
  logger: loggerStream

store.shareClient.use 'connect', (shareRequest, next) ->
  {agent, stream, req} = shareRequest
  agent.connectSession = req.session if req
  next()

store.on 'bundle', (browserify) ->
  browserify.add publicDir + '/js/jquery-1.9.1.min.js'
  GLOBAL.CodeMirror = {}
  browserify.add publicDir + '/js/3rdparty.js'
  # Add support for directly requiring coffeescript in browserify bundles
  browserify.transform coffeeify

#Middlewares
#Everyauth

findOrCreateUser = (service, session, accessToken, accessTokenExtra, sourceUser) ->
  promise = @Promise()
  accessToken = accessToken+""
  model = store.createModel()
  #usersQuery = model.query("users_secure.*.service.#{service}", { token: accessToken})
  queryObj = {}
  queryObj["service.#{service}.token"] = accessToken
  usersQuery = model.query("users_secure", queryObj)
  promise.callback (user) ->
    console.log "USER", user
  #  path = "users.#{user.id}"
  #model.fetch path, (err) ->
  #  model.set path + ".loggedin", +new Date
  #  return user.id

  usersQuery.fetch (err) ->
    return promise.fail err if err
    sec_user = usersQuery.get()[0]
    path = "users.#{sec_user?.id}"
    console.log "PATH", path
    model.fetch path, (err) ->
      return promise.fail err if err
      user = model.get path
      console.log "this is a user", user
      return promise.fulfill user if user
      #create a new user if we didn't find one
      serviceObj = {}
      serviceObj[service] = sourceUser
      user = {services: serviceObj }
      userId = model.add 'users', user
      user.id = userId
      serviceObj = {}
      serviceObj[service] = { token: accessToken }
      model.add 'users_secure', {id: userId, service: serviceObj }, (err) ->
        return promise.fail err if err
        return promise.fulfill user
  return promise

#redirectPath = (req, res) -> req.query['continue'] || app.pages.url app.pages.inlet.new
redirectPath = '/i'

everyauth.github
  .entryPath('/auth/github')
  .callbackPath('/auth/github/callback')
  .scope('gist')
  .appId(conf.github.appId)
  .appSecret(conf.github.appSecret)
  .findOrCreateUser( (session, accessToken, accessTokenExtra, ghUser) ->
      return findOrCreateUser.call(@, 'github', session, accessToken, accessTokenExtra, ghUser))
  .redirectPath redirectPath

#everyauth
#  .twitter
#    .consumerKey(conf.twit.consumerKey)
#    .consumerSecret(conf.twit.consumerSecret)
#    .findOrCreateUser( (session, accessToken, accessSecret, twitUser) ->
#      return findOrCreateUser.call(@, 'twitter', session, accessToken, accessTokenExtra, twitUser))
#  .redirectPath redirectPath
#everyauth.instagram
#  .appId(conf.instagram.clientId)
#  .appSecret(conf.instagram.clientSecret)
#  .scope('basic')
#  .findOrCreateUser( (session, accessToken, accessTokenExtra, hipster) ->
#      return findOrCreateUser.call(@, 'instagram', session, accessToken, accessTokenExtra, hipster))
#  .redirectPath redirectPath
#everyauth.tumblr
#  .consumerKey(conf.tumblr.consumerKey)
#  .consumerSecret(conf.tumblr.consumerSecret)
#  .findOrCreateUser( (session, accessToken, accessSecret, tumblrUser) ->
#    return findOrCreateUser.call(@, 'tumblr', session, accessToken, accessTokenExtra, tumblr))
#  .redirectPath redirectPath
#

everyauth.everymodule
  .findUserById( (req, userId, cb) ->
    model = req.getModel()
    path = "users.#{userId}"
    model.fetch path, (err) ->
      cb err if err
      user = model.get path
      cb(null, user))

afterAuthMiddleware = (req, res, next) ->
  # Ignore routes underneath auth
  return next() if req.url.slice(0, 6) == '/auth/'
  model = req.getModel()
  console.log "huh"
  unless userId = model.get '_session.userId'
    console.log("wuh?")
    return next()
    #return res.redirect '/auth/github', {continue: req.url}
  path = "users.#{userId}"
  model.set path + ".loggedin", +new Date
  return next()

createUserId = (req, res, next) ->
  model = req.getModel()
  model.set '_session.userId', req.session.auth?.userId

  #TODO: setup real auth
  #model.set '_session.userId', '1234'
  #model.set '_session.userName', 'enjafox'
  #model.set '_session.userId', req.session.auth?.userId
  next()

ipMiddleware = (req, res, next) ->
  forwarded = req.header 'x-forwarded-for'
  ipAddress = forwarded && forwarded.split(',')[0] ||
    req.connection.remoteAddress

  model = req.getModel()
  model.set '_info.ipAddress', ipAddress
  next()

expressApp
  .use(express.favicon())

  .use('/static', gzippo.staticGzip publicDir, maxAge: ONE_YEAR)
  # Gzip dynamically rendered content
  .use(express.compress())
  .use(app.scripts(store))

  .use(express.cookieParser())
  .use(express.session
    secret: process.env.SESSION_SECRET || 'YOUR SECRET HERE'
    store: new MongoStore(url: 'mongo://' + conf.mongo.uri, safe: true)
  )

  # Add browserchannel client-side scripts to model bundles created by store,
  # and return middleware for responding to remote client messages
  .use(racerBrowserChannel store)
  # Adds req.getModel method
  .use(store.modelMiddleware())

  #.use(ipMiddleware)

  .use(createUserId)
  .use(everyauth.middleware())
  #.use(afterAuthMiddleware)


  # Creates an express middleware from the app's routes
  .use(app.router())
  .use(expressApp.router)
  .use(serverError())

expressApp.all '*', (req, res, next) ->
  next '404: ' + req.url
