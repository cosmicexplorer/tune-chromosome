# @flow

React = require 'react'
ReactDOM = require 'react-dom'

{ViewSwitcher} = require './frontend/views'

reactStart = ->
  rootDiv = document.getElementById 'root'
  if rootDiv?
    ReactDOM.render <ViewSwitcher />, rootDiv
  else
    throw new Error 'could not find tag #root!'

window.onload = reactStart
