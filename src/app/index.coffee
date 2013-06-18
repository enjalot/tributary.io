derby = require('derby')

app = derby
  .createApp(module)
  .use(require '../../ui/index.coffee')

require './pages.coffee'
require './inlet.coffee'

app.ready (model) ->
  window.model = model

['get', 'post', 'put', 'del'].forEach (method) ->
  app[method] app.pages.submit.href, (page, model, {body, query}) ->
    args = JSON.stringify {method, body, query}, null, '  '
    page.render 'submit', {args}


app.get app.pages.home.href, (page) ->
  page.render 'home'

app.get app.pages.error.href, ->
  throw new Error 500

app.get app.pages.back.href, (page) ->
  page.redirect 'back'
