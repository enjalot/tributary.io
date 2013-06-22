Transform = require('stream').Transform
util = require('util')
moment = require('moment')

module.exports = () ->
  color = require('ansi-color').set
  bold = (value)-> return color(value, 'bold')
  black = (value)-> return color(value, 'black')
  red = (value)-> return color(value, 'red')
  green = (value)-> return color(value, 'green')
  yellow = (value)-> return color(value, 'yellow')
  blue = (value)-> return color(value, 'blue')
  magenta = (value)-> return color(value, 'magenta')
  cyan = (value)-> return color(value, 'cyan')
  white = (value)-> return color(value, 'white')

  stream = new Transform({objectMode: true})

  origPush = stream.push
  stream.push = (value) ->
    origPush.call(this, value + ' ')

  stream._transform = (data, encoding, callback) ->
    if data.chunk
      chunk = data.chunk
    else
      chunk = data
    # console.log('chunk', chunk)

    stream.push white(moment().format("YYYY/MM/DD HH:mm:ss Z"))
    if data.client?.id
      stream.push yellow(data.client.id)

    if data.type == 'C->S' # Client to Server or vice versa
      stream.push bold(cyan(data.type))
    else if data.type == 'S->C'
      stream.push bold(blue(data.type))
    else
      stream.push bold(magenta('*S*'))

    if chunk?.a # Action
      stream.push magenta(chunk.a)

    if chunk?.c # collection
      stream.push  green(chunk.c)

    if chunk?.doc # Doc ids
      stream.push green(chunk.doc)

    if chunk?.id # Id of subs/queries
      stream.push green(chunk.id)

    if chunk?.q # Query parameters
      stream.push green(util.inspect(chunk.q, {depth:null}))

    if chunk?.data && chunk.a != 'qsub' && chunk.a != 'qfetch' # Data being sent
      stream.push green(util.inspect(chunk.data, {depth:2}))

    if chunk?.op # Changes
      stream.push green(util.inspect(chunk.op, {depth: null}))

    if chunk?.create # Creation
      stream.push green('[Create] ' + util.inspect(chunk.create, {depth: null}))

    stream.push('\n')

    callback()

  return stream
