app = require('derby').createApp module
require './pages.coffee'

require './inlet.coffee'

['get', 'post', 'put', 'del'].forEach (method) ->
  app[method] app.pages.submit.href, (page, model, {body, query}) ->
    args = JSON.stringify {method, body, query}, null, '  '
    page.render 'submit', {args}

app.get app.pages.error.href, ->
  throw new Error 500

app.get app.pages.back.href, (page) ->
  page.redirect 'back'
