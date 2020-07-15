# @flow

{
  AppState, Main, FilterSelect, SelectInput, SelectFilterParameter, Silence,
  NullResource, FilterRequest, InputSetRequest, FilterParameterRequest,
  Select, ResourceMapping,
} = require '../state-machine/operations'
{classOf} = require '../util/util'

{useState, useEffect} = React = require 'react'


MainView = ({selectOperator, appState, setAppState}) ->
  <div className="main">
    <p>MAIN</p>
    <button onClick={-> setAppState selectOperator.invoke(appState)}>Select Filter</button>
  </div>


FilterSelectView = ->
  <div className="filter-select">
    <p>FILTER-SELECT</p>
  </div>


SelectInputView = ->
  <div className="select-input">
    <p>SELECT-INPUT</p>
  </div>


SelectFilterParameterView = ->
  <div className="select-filter-parameter">
    <p>SELECT-FILTER-PARAMETER</p>
  </div>


ViewSwitcher = ->
  [resource, setResource] = useState###::< Resource >###(new NullResource)
  useEffect -> ->

  [appState, setAppState] = useState###::< AppState >###(
    new AppState Silence, new Main, ResourceMapping, setResource)
  useEffect -> ->

  switch classOf resource
    when NullResource then <MainView
      selectOperator={new Select} appState={appState} setAppState={setAppState} />
    when FilterRequest then <FilterSelectView />
    when InputSetRequest then <SelectInputView />
    when FilterParameterRequest then <SelectFilterParameterView />
    else throw resource


module.exports = {ViewSwitcher}
