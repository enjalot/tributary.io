derby = require('derby')

app = derby
  .createApp(module)
  .use(require '../../ui/index.coffee')

require './pages.coffee'
require './inlet.coffee'

app.ready (model) ->
  window.model = model
  require('CodeMirror')

app.get app.pages.list.href, (page, model) ->
  inletsQuery = model.query 'inlets', {}
  model.subscribe inletsQuery, (err) ->
    # TODO: handle error
    inletsQuery.ref '_page.inlets'
    page.render 'list'

app.get app.pages.home.href, (page) ->
  page.render 'home'
