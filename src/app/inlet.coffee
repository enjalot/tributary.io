app = require './index.coffee'


inletPage = (page, model, params, next) ->
  console.log("params", params)

  #TODO: validate this a little
  gistId = params.gistId
  model.set '_page.gistId', gistId

  inletsQuery = model.query 'inlets',
    gistId: gistId

  inlets = model.at 'tributary.inlet'
  uuid = model.at 'tributary.uuid'

  model.subscribe inlets, uuid, (err) ->
    return next err if err
    id = uuid.get()
    if gistId
      inletQuery = model.query 'tributary.inlet', { $orderby: {createdAt: -1}, $limit: 5}
      inletQuery.subscribe (err) ->
        console.log "INLET", inletQuery.get()
      #TODO: look up uuid from gistId query
      #filtered = inlets.filter (d) -> d.gistId == gistId
      #console.log 'filtered', filtered.get()
      if not id
        id = gistId
    else
      if not id
        id = generateUUID()

    console.log 'uuid', id
    uuid.set id
    inlet = inlets.at id
    inlet.setNull
      code: ""
      uuid: id
      createdAt: +new Date
    if gistId
      inlet.set 'gistId', gistId

    console.log inlet.get()
    page.render 'inlet'


blankInletPage = (page, model, params, next) ->
  inlets = model.at 'tributary.inlet'
  uuid = model.at 'tributary.uuid'
  id = generateUUID()

  model.subscribe inlets, uuid, (err) ->
    uuid.set id
    inlet = inlets.at id
    inlet.setNull
      code: ""
      uuid: id
      createdAt: +new Date

  page.render 'inlet'

inletEnter = ->
  cm = CodeMirror document.getElementById('testcodemirror'), {
    theme: 'lesser-dark'
  }
  cm.setValue """
    var x = 5;
    var s = "this is some code;"
  """

app.get app.pages.inlet.gist, inletPage
app.get app.pages.inlet.root, blankInletPage

app.enter app.pages.inlet.gist, inletEnter
app.enter app.pages.inlet.root, inletEnter

app.ready (model) ->
  #table = model.at 'sink.table'
  #rows = table.at 'rows'
  #cols = table.at 'cols'

app.selectFiles = () ->
  console.log "files"
  control = @model.get '_page.control'
  if control == 'files'
    @model.set '_page.control', null
  else
    @model.set '_page.control', 'files'
app.selectSettings = () ->
  console.log "settings"
  control = @model.get '_page.control'
  if control == 'settings'
    @model.set '_page.control', null
  else
    @model.set '_page.control', 'settings'
app.selectCode = () ->
  console.log "code"
  control = @model.get '_page.control'
  if control == 'code'
    @model.set '_page.control', null
  else
    @model.set '_page.control', 'code'
app.selectTools = () ->
  console.log "tools"
  control = @model.get '_page.control'
  if control == 'tools'
    @model.set '_page.control', null
  else
    @model.set '_page.control', 'tools'
app.selectFullscreen = () ->
  console.log "fullscreen"





generateUUID = ->
  uid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
    r = Math.random()*16|0
    if c == 'x'
      v = r
    else
      v = (r&0x3|0x8)
    return v.toString(16)
  return uid
