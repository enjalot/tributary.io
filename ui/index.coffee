viewUtil = require './util/view'

config =
  ns: 'ui'
  filename: __filename
  scripts:
    editor: require './editor'
  styles: './styles'

module.exports = ui = (derby, options) ->
  library = derby.createLibrary config, options
  viewUtil library.view

ui.decorate = 'derby'
