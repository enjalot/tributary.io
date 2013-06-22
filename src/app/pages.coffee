app = require './index.coffee'
querystring = require 'qs'
viewPath = require 'derby/lib/viewPath'

util = require('derby').util
if util.isServer
  origin = 'http://localhost:3001'
else
  origin = window.document.location.origin


app.pages =
  home:
    title: 'Home'
    href: '/'
  inlet:
    title: 'inlet'
    new: '/i'                     #create a new inlet
    #user: '/i/:userName'          #user page
    inlet: '/i/:userName/:inlet'  #an existing inlet
    #gist: '/inlet/:gistId'        #backwards compatible
  list:
    href: '/list'

navOrder = [
  'home'
  'inlet'
]

app.pages.url = (name, params) ->
  route = viewPath.lookup name, app.pages
  unless route
    return console.trace 'No route found for ', name, params
  return route unless params
  i = 0
  keys = []
  url = route.replace /(?:(?:\:([^?\/:*]+))|\*)\??/g, (match, key) ->
    if key
      keys.push key
      return params[key]
    return params[i++]
  unless Array.isArray params
    qs = {}
    for k, v of params
      if keys.indexOf(k) == -1
        qs[k] = v
    url += '?' + querystring.stringify(qs) if Object.keys(qs).length
  return origin + url

# TODO: Derby should be able to parse object notation better
# For now, this function assumes key and value pairs are supplied
# in alternating order after the route name
app.pages.viewFn = (name, args...) ->
  params = {}
  key = null
  for arg, i in args
    if i % 2
      params[key] = arg
    else
      key = arg
  return app.pages.url name, params

app.view.fn 'url', app.pages.viewFn

app.view.fn 'pageTitle', (current) ->
  return app.pages[current]?.title
