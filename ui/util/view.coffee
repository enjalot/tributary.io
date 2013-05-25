module.exports = (view) ->
  #some array functions
  view.fn 'slice', slice
  view.fn 'last', last

  
slice = (value, begin, end) ->
  return value && value.slice && value.slice begin, end

#check if this array element is the last one
last = (index, array) ->
  index == array.length - 1

