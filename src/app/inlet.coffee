app = require './index.coffee'

app.get app.pages.inlet.href, (page, model, params, next) ->
  inlet = model.at 'tributary.inlet'
  inlet.subscribe (err) ->
    return next err if err
    inlet.setNull
      rows: [
        {name: 1, cells: [{}, {}, {}]}
        {name: 2, cells: [{}, {}, {}]}
      ]
      lastRow: 1
      cols: [
        {name: 'A'}
        {name: 'B'}
        {name: 'C'}
      ]
      lastCol: 2
    page.render 'inlet'


app.ready (model) ->
  #table = model.at 'sink.table'
  #rows = table.at 'rows'
  #cols = table.at 'cols'


