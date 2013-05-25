app = require './index.coffee'

app.pages =
  home:
    title: 'Home'
    href: '/'
  inlet:
    title: 'inlet'
    root: '/inlet'
    gist: '/inlet/:gistId'
  back:
    title: 'Back redirect'
    href: '/back'
  submit:
    title: 'Submit form'
    href: '/submit'
  error:
    title: 'Error test'
    href: '/error'

navOrder = [
  'home'
  'inlet'
  'back'
  'error'
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
