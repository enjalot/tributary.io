app = require './index.coffee'


inletPage = (page, model, params, next) ->
  console.log("params", params)

  page.render 'inlet'


blankInletPage = (page, model, params, next) ->
  #TODO: work out schema more completely
  model.setNull '_page.inlet',
    files:
      inlet:
        type: 'javascript'
        ext: 'js'
        code: """
  var x = 6;
  var s = "this is some code;"
        """
    uuid: model.id()
    createdAt: +new Date
    userId: model.get '_session.userId'

  page.render 'inlet'

blankInletEnter = (model) ->
  # Save in localStorage for inlet that hasn't been saved yet
  # TODO: creating a new inlet or saving should clear localStorage
  # so next new one will be blank again
  inlet = localStorage.getItem 'blankInlet'
  if inlet
    try
      model.pass({localStorage:true}).set '_page.inlet', JSON.parse(inlet)
    catch e
      #pass
  model.on 'change', '_page.inlet.files.*.code', (fileName, newCode, oldCode, passed) ->
    return if passed?.localStorage
    localStorage.setItem 'blankInlet', JSON.stringify(model.get '_page.inlet')
  inletEnter(model)

inletEnter = (model) ->
  # Initialize client side code (tributary + codemirror)
  # TODO: setup CM for each file
  # TODO: check hash params for signal not to auto-execute
  cm = CodeMirror document.getElementById('codemirror'), {
    theme: 'lesser-dark'
  }
  path = '_page.inlet.files.inlet.code'
  initCode = model.get path
  # TODO: setup actual tributary library
  cm.setValue initCode

  cm.on 'change', (_, op) ->
    # update code in model when editor's code changes
    start = cm.indexFromPos(op.from)
    if rlen = op.removed[0].length
      model.pass({fileName: 'inlet'}).stringRemove(path, start, rlen)
    if op.text[0].length
      model.pass({fileName: 'inlet'}).stringInsert(path, start, op.text[0])

  model.on 'change', '_page.inlet.files.*.code', (fileName, newCode, oldCode, passed) ->
    #we don't want to update CM if it was CM that updated us
    return if passed?.fileName == fileName
    #TODO: use filename to look up appropriate cm instance
    cm.setValue newCode

# Handle the routes
app.get app.pages.inlet.new, blankInletPage
app.enter app.pages.inlet.new, blankInletEnter

app.get app.pages.inlet.inlet, inletPage
app.enter app.pages.inlet.inlet, inletEnter

# Backwards compatibility
#app.get app.pages.inlet.gist, gistPage
#app.enter app.pages.inlet.gist, gistEnter

app.ready (model) ->
  #table = model.at 'sink.table'
  #rows = table.at 'rows'
  #cols = table.at 'cols'

app.fn 'selectFiles',  ->
  console.log "files"
  control = @model.get '_page.control'
  if control == 'files'
    @model.set '_page.control', null
  else
    @model.set '_page.control', 'files'
app.fn 'selectSettings', ->
  console.log "settings"
  control = @model.get '_page.control'
  if control == 'settings'
    @model.set '_page.control', null
  else
    @model.set '_page.control', 'settings'
app.fn 'selectCode', ->
  console.log "code"
  control = @model.get '_page.control'
  if control == 'code'
    @model.set '_page.control', null
  else
    @model.set '_page.control', 'code'
app.fn 'selectTools', ->
  console.log "tools"
  control = @model.get '_page.control'
  if control == 'tools'
    @model.set '_page.control', null
  else
    @model.set '_page.control', 'tools'
app.fn 'selectFullscreen', ->
  console.log "fullscreen"

sanitizeInletName = (text) ->
  text

#Saving logic
app.fn 'save', ->
  console.log "save"
  #save the version number (get op # from share)
  #add to collection if inlet isn't already in the collection

app.fn 'fork', ->
  console.log "fork"
  #add _page.inlet to collection under new name + id

app.fn 'exportToGist', ->
  console.log "export to gist"
