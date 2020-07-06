# @flow

React = require 'react'
ReactDOM = require 'react-dom'

{MainView} = require './frontend/views'

reactStart = ->
  rootDiv = document.getElementById 'root'
  if rootDiv?
    ReactDOM.render <MainView />, rootDiv
  else
    throw new Error 'could not find tag #root!'

window.onload = reactStart
