# @flow

React = require 'react'
ReactDOM = require 'react-dom'

{AppState, Main, Silence, ResourceMapping} = require './state-machine/operations'
{ViewSwitcher} = require './frontend/views'

reactStart = ->
  rootDiv = document.getElementById 'root'
  if rootDiv?
    appState = new AppState Silence, new Main, ResourceMapping
    ReactDOM.render <ViewSwitcher state={appState} />, rootDiv
  else
    throw new Error 'could not find tag #root!'

window.onload = reactStart
