@flow

This `require()` call is needed for any file that uses coroutines to polyfill for the browser!

    require 'regenerator-runtime/runtime'

    {DiscreteInputEvent, InputEventsStream, InputRegistry, Keypress, UpdateRegistryBindings} = require '../input/input'
    ###::
      import type {RegistryOperation} from '../input/input'
    ###

    {
      AppState, Main, FilterSelect, SelectInput, SelectFilterParameter, Silence,
      Select, Filter, InputMapping, NullResource, FilterNode, Resource, Keypress,
      View,
    } = require '../state-machine/operations'

    {useState, useEffect, useReducer, useContext} = React = require 'react'

# Views
## MainView

    mainDefaultInputRegistry =
      s: new InputEventsStream

    ###::
      type _mainOptions = {|
        appState: AppState,
        inputRegistry: InputRegistry,
      |}
    ###
    MainView = (opts###: _mainOptions###) ->
      {appState, inputRegistry} = opts
      appDispatch = useContext AppStateDispatch

      additionalInputsToRegister = new InputRegistry
      [inputRegistry, inputDispatch] = useInputRegistry additionalInputsToRegister

      <CurrentInputRegistry.Provider value={[inputRegistry, inputDispatch]}>
        <div className="main">
          <p>MAIN</p>
          <>
            <button onClick={-> appDispatch new Select}>
              Select Filter
            </button>
          </>
        </div>
      </CurrentInputRegistry.Provider>

## FilterSelectView

    ###::
      type _filterSelectOptions = {|
        appState: AppState,
      |}
    ###
    FilterSelectView = (opts###: _filterSelectOptions###) ->
      {appState} = opts
      {activeResource} = appState
      [filterState, setFilterState] = useState###::< Filter >###(new Filter new InputMapping)
      useEffect -> ->

      additionalInputsToRegister = new InputRegistry
      [inputRegistry, inputDispatch] = useInputRegistry additionalInputsToRegister

      [resolveFilter, _reject] = appState.resourceMapping.getNow activeResource

      <CurrentInputRegistry.Provider value={[inputRegistry, inputDispatch]}>
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
      </CurrentInputRegistry.Provider>

## SelectInputView

    SelectInputView = ->
      <div className="select-input">
        <p>SELECT-INPUT</p>
      </div>

## SelectFilterParameterView

    SelectFilterParameterView = ->
      <div className="select-filter-parameter">
        <p>SELECT-FILTER-PARAMETER</p>
      </div>

## ViewSwitcher

    ###::
      type _viewSwitcherOptions = {|
        eventsStream: InputEventsStream,
      |}
    ###
    ViewSwitcher = (opts###: _viewSwitcherOptions###) ->
      {registries, eventsStream} = opts
      [appState, appDispatch] = useAppState()

      <AppStateDispatch.Provider value={appDispatch}>
        <KeyboardEventsStream.Provider value={eventsStream}>{
          switch appState.activeView.constructor
            when Main then <MainView appState={appState} />
            when FilterSelect then <FilterSelectView appState={appState} />
            when SelectInput then <SelectInputView />
            when SelectFilterParameter then <SelectFilterParameterView />
            else throw activeView
        }</KeyboardEventsStream.Provider>
      </AppStateDispatch.Provider>

# Hooks
## useInputRegistry

    CurrentInputRegistry = React.createContext null

    KeyboardEventsStream = React.createContext null

    ###::
      type _inputRegistryInit = {|
        parent: InputRegistry,
        child: InputRegistry,
      |}
    ###
    initializeInputRegistry = (args###: _inputRegistryInit###)###: InputRegistry### ->
      {parent, child} = args
      parent.merge child

    useInputRegistry = (newRegistry###: InputRegistry###) ->
      [parentRegistry, _] = (useContext CurrentInputRegistry) ? [new InputRegistry, null]

      [curRegistry, dispatch] = useReducer(
        ((registry, operation###: RegistryOperation###) -> operation.invoke registry),
        {parent: parentRegistry, child: newRegistry},
        initializeInputRegistry)

      eventsStream = useContext KeyboardEventsStream
      useEffect ->
        eventsStream.subscribeExclusive (keyCode) -> dispatch new Keypress keyCode
        -> eventsStream.unsubscribeRemaining()

      [curRegistry, dispatch]

## useAppState

    AppStateDispatch = React.createContext null

    ###::
      type _appStateInit = {|
        filterNode: FilterNode,
        view: View,
        resource: Resource,
      |}
    ###
    initializeAppState = (args###: _appStateInit###) ->
      {filterNode, view, resource} = args
      new AppState filterNode, view, resource

    useAppState = ->
      [appState, dispatch] = useReducer(
        ((state, operator) -> await operator.invoke state),
        {filterNode: Silence, view: new Main, resource: new NullResource},
        initializeAppState)

      [appState, dispatch]

# Exports

    module.exports = {ViewSwitcher}
