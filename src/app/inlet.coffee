app = require './index.coffee'


inletPage = (page, model, params, next) ->
  console.log("params", params)

  userName = params.userName
  # TODO: lookup id from username
  # getUserFromName(model, userName, (err, user) ->
  userId = '1234'
  inletTitle = params.inlet
  inletQuery = model.query 'inlets', {userId: userId, title: inletTitle}
  model.subscribe inletQuery, (err) ->
    # TODO: proper 404? redirect to blank for now
    # TODO: handle error
    return console.log("ERROR", err) if err
    return app.history.push(app.pages.url('inlet.new')) if not (inlet = inletQuery.get()[0])
    console.log "INLET", inlet
    model.ref "_page.inlet", "inlets.#{inlet.id}"
    model.set '_page.inletTitle', inlet.name

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
  model.setNull '_page.inletTitle', 'new inlet'

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

resetLocalStorage = (model) ->
  inlet =
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

  localStorage.setItem 'blankInlet', JSON.stringify(inlet)

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


sanitizeUserName = (text) -> text
checkUserName = (model, cb) ->
  # TODO: make usernames unique, check similar to inlet titles

getUserFromName = (model, userName, cb) ->
  userQuery = model.query 'users', { name: userName }
  model.fetch userQuery, (err) ->
    return cb(err) if err
    user = model.query.get()[0]
    cb(null, user)

sanitizeInletTitle = (text) ->
  text
    .replace(/\W/g,'-')

checkTitle = (model, cb) ->
  text = model.get '_page.inletTitle'
  return cb(null, null) if not text
  text = sanitizeInletTitle(text)
  userId = model.get '_session.userId'
  titleQuery = model.query 'inlets', { userId: userId, title: text }
  model.fetch titleQuery, (err) ->
    return cb(err) if err
    if not titleQuery.get().length
      model.set '_page.titleValidation', 'valid'
      valid = true
    else
      model.set '_page.titleValidation', 'invalid'
      valid = false
    model.unfetch titleQuery, (err) ->
      return cb(err) if err
      cb(null, valid)

app.on 'model', (model) ->
  model.set '_page.loading', true
  model.setNull '_page.controls', [
    'files', 'settings', 'tools', 'publish'
  ]

app.ready (model) ->
  model.set '_page.loading', false
  checkTitle(model, ->)
  model.on 'change', '_page.inletTitle', ->
    checkTitle(model, ->)

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
    
app.fn 'selectPublish',  ->
  console.log "publish"
  control = @model.get '_page.control'
  if control == 'publish'
    @model.set '_page.control', null
  else
    @model.set '_page.control', 'publish'
        
app.fn 'selectFullscreen', ->
  console.log "fullscreen"
  $("#box-2").toggleClass("hidden-code")

#Saving logic
app.fn 'save', ->
  model = @model
  return if !model.get('_page.titleValidation') == 'valid'
  console.log "save"
  #save the version number (get op # from share)
  #add to collection if inlet isn't already in the collection
  inlet = model.get '_page.inlet'
  title = model.get '_page.inletTitle'
  inlet.title = sanitizeInletTitle(title)
  inlet.name = title
  path = "inlets.#{inlet.id}"
  model.fetch path, (err) ->
    if not model.get path
      model.add 'inlets', inlet, (err) ->
        # TODO: handle error
        return err if err
        url = app.pages.url 'inlet.inlet', { userName: model.get('_session.userName'), inlet: inlet.title}
        resetLocalStorage(model)
        model.unfetch path, (err) ->
          # TODO: handle error
          return err if err
          app.history.push url

app.fn 'fork', ->
  console.log "fork"
  #add _page.inlet to collection under new name + id

app.fn 'new', ->
  console.log "new"
  #add _page.inlet to collection under new name + id
  resetLocalStorage(@model)
  app.history.push app.pages.url 'inlet.new'


app.fn 'exportToGist', ->
  console.log "export to gist"
