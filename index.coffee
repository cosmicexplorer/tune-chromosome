# @flow

React = require 'react'
ReactDOM = require 'react-dom'

reactStart = -> ReactDOM.render <p>asdf</p>, document.getElementById 'root'

window.onload = reactStart
