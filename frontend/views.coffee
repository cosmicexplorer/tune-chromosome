# @flow

{
  AppState, Main, FilterSelect, SelectInput, SelectFilterParameter, Silence,
  NullResource, FilterRequest, InputSetRequest, FilterParameterRequest,
  Select,
} = require '../state-machine/operations'
{classOf} = require '../util/util'

{useState, useEffect} = React = require 'react'


MainView = ({selectOperator, appState}) ->
  <div className="main">
    <p>MAIN</p>
    <button onClick={-> selectOperator.invoke appState}>Select Filter</button>
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


###::
  type _viewSwitcherProps = {|
    state: AppState,
  |}
###

ViewSwitcher = ({state: appState}) ->
  [resource, setResource] = useState###::< Resource >###(new NullResource)
  # FIXME: this basically monkey patches in the UI change to the AppState instance after the fact?
  appState.setResourceUICallback = setResource
  useEffect -> ->

  switch classOf resource
    when NullResource then <MainView appState={appState} selectOperator={new Select} />
    when FilterRequest then <FilterSelectView />
    when InputSetRequest then <SelectInputView />
    when FilterParameterRequest then <SelectFilterParameterView />
    else throw resource


module.exports = {ViewSwitcher}
