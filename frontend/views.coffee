# @flow

{Main, FilterSelect, SelectInput, SelectFilterParameter} = require '../state-machine/operations'

{useState, useEffect} = React = require 'react'


MainView = ->
  <div className="main-view">
    <p>MAIN</p>
  </div>


FilterSelectView = ->
  <div className="filter-select-view">
    <p>FILTER-SELECT</p>
  </div>


SelectInputView = ->
  <div className="select-input-view">
    <p>SELECT-INPUT</p>
  </div>


SelectFilterParameterView = ->
  <div className="select-filter-parameter-view">
    <p>SELECT-FILTER-PARAMETER</p>
  </div>


module.exports = {MainView, FilterSelectView, SelectInputView, SelectFilterParameterView}
