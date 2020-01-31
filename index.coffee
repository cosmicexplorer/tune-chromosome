# @flow

React = require 'react'
ReactDOM = require 'react-dom'

pTag = (txt) -> <p>{txt}</p>

reactStart = ->
  rootDiv = document.getElementById 'root'
  if rootDiv?
    ReactDOM.render pTag('wow!'), rootDiv
  else
    throw new Error 'could not find tag #root!'

window.onload = reactStart
