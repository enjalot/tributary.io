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
    if gistId
      inlet.set 'gistId', gistId

    console.log inlet.get()
    page.render 'inlet'

    
blankInletPage = (page, model, params, next) ->
  page.render 'inlet'

app.get app.pages.inlet.gist, inletPage
app.get app.pages.inlet.root, blankInletPage

app.ready (model) ->
  #table = model.at 'sink.table'
  #rows = table.at 'rows'
  #cols = table.at 'cols'


generateUUID = ->
  uid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
    r = Math.random()*16|0
    if c == 'x'
      v = r
    else
      v = (r&0x3|0x8)
    return v.toString(16)
  return uid
