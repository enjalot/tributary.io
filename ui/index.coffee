viewUtil = require './util/view.coffee'

config =
  ns: 'ui'
  filename: __filename
  scripts:
    editor: require './editor/index.coffee'
  styles: './styles'

module.exports = ui = (derby, options) ->
  library = derby.createLibrary config, options
  viewUtil library.view

ui.decorate = 'derby'
