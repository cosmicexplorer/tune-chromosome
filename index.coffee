# @flow

React = require 'react'
ReactDOM = require 'react-dom'

{AnimatedObject} = require './frontend/app'

reactStart = ->
  rootDiv = document.getElementById 'root'
  if rootDiv?
    ReactDOM.render <AnimatedObject me="me2" />, rootDiv
  else
    throw new Error 'could not find tag #root!'

window.onload = reactStart
