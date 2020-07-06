# @flow

{useState, useEffect} = React = require 'react'

###::
type Props = {|
  me: ?string,
|}

type State = Array<string>
###

# ExampleComponent = (props###: Props###) ->
#   {me = 'me'} = props
#   [items, setItems] = useState###::< State >###([
#     'hello'
#     'world'
#     'click'
#     me
#   ])
#   useEffect ->
#     # Do stateful, business logic stuff when the element is rendered...
#     # Then return a closure which performs any business logic cleanup stuff!
#     ->

#   appendItem = -> setItems [items..., prompt('Enter some text')]

#   removeItem = (i###: number###) -> setItems items.filter (_, j) -> i isnt j

#   renderedItems = items.map (item, i) ->
#     <div key={item} onClick={-> removeItem i}>
#       {item}
#     </div>

#   <div>
#     <button onClick={appendItem}>Add Item</button>
#     {renderedItems}
#   </div>

# module.exports = {ExampleComponent}
