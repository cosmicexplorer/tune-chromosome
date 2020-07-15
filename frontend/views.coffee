# @flow

require 'regenerator-runtime/runtime'

{
  AppState, Main, FilterSelect, SelectInput, SelectFilterParameter, Silence,
  Select, Filter, InputMapping, NullResource, FilterNode, Resource,
} = require '../state-machine/operations'
###::
  import type {SetAppStateCallback} from '../state-machine/operations';
###

{TypedMap} = require '../util/collections'
{classOf} = require '../util/util'

{useState, useEffect} = React = require 'react'


###::
  type _mainOptions = {|
    selectOperator: Select,
    appState: AppState,
    setAppState: SetAppStateCallback,
  |}
###
MainView = (opts###: _mainOptions###) ->
  {selectOperator, appState, setAppState} = opts
  <div className="main">
    <p>MAIN</p>
    <button onClick={-> setAppState await selectOperator.invoke appState, setAppState}>
      Select Filter
    </button>
  </div>


###::
  type _filterSelectOptions = {|
    appState: AppState,
    resource: Resource,
  |}
###
FilterSelectView = (opts###: _filterSelectOptions###) ->
  {appState, resource} = opts
  [filterState, setFilterState] = useState###::< Filter >###(
    new Filter new InputMapping new TypedMap)
  useEffect -> ->

  [resolveFilter, _reject] = appState.resourceMapping.getNow resource
  <div className="filter-select">
    <p>FILTER-SELECT</p>
    <button onClick={->
      pipedNode = new FilterNode
        filter: filterState
        name: ''
        source: null
        output: null
        timestamp: new Date
      resolveFilter pipedNode
    }>
      Confirm Filter Selection
    </button>
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
  [appState, setAppState] = useState###::< AppState >###(
    new AppState Silence, new Main, new TypedMap)
  useEffect -> ->

  {activeView, activeResource} = appState

  switch classOf activeView
    when Main then <MainView
      selectOperator={new Select} appState={appState} setAppState={setAppState} />
    when FilterSelect then <FilterSelectView appState={appState} resource={activeResource} />
    when SelectInput then <SelectInputView />
    when SelectFilterParameter then <SelectFilterParameterView />
    else throw activeView


module.exports = {ViewSwitcher}
