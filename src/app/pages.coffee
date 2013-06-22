app = require './index.coffee'

app.pages =
  home:
    title: 'Home'
    href: '/'
  inlet:
    title: 'inlet'
    new: '/i'                     #create a new inlet
    #user: '/i/:username'          #user page
    inlet: '/i/:username/:inlet'  #an existing inlet
    #gist: '/inlet/:gistId'        #backwards compatible

navOrder = [
  'home'
  'inlet'
]

app.view.fn 'navItems', (current) ->
  items = []
  for ns in navOrder
    page = app.pages[ns]
    items.push
      title: page.title
      href: page.href
      isCurrent: current == ns
  items[items.length - 1].isLast = true
  return items

app.view.fn 'pageTitle', (current) ->
  return app.pages[current]?.title
