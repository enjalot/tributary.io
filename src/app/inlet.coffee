app = require './index.coffee'


inletpage = (page, model, params, next) ->
  console.log("params", params)

  #TODO: validate this a little
  gistId = params.gistId
  inlets = model.at 'tributary.inlet'
    
  inlets.subscribe (err) ->
    return next err if err
    if gistId
      #TODO: look up uuid from gistId query
      uuid = model.get 'uuid'
    else
      uuid = model.get 'uuid'

    console.log 'uuid', uuid
    inlet = inlets.at uuid

    inlet.setNull
      code: ""
      uuid: uuid

    page.render 'inlet'


app.get app.pages.inlet.gist, inletpage
app.get app.pages.inlet.root, inletpage

app.ready (model) ->
  #table = model.at 'sink.table'
  #rows = table.at 'rows'
  #cols = table.at 'cols'


