# @flow

assert = require 'assert'

class StateSet ###::<T>###
  ###::
    states: Array<T>
  ###
  constructor: (@states) ->

  extractDimensions: (numDimensions ###: number###) ###: [StateSet<T>, StateSet<T>]### ->
    remaining = @states.length - numDimensions
    assert.ok remaining >= 0, "too many dimensions #{numDimensions}
                               extracted from state set
                               with only #{@states.length} states: #{JSON.stringify @}"

    extracted = @states[..numDimensions]
    remaining = @states[numDimensions..]
    # TODO: figure out some way of making using of the prototype chain here???
    [
      new StateSet states: extracted
      new StateSet states: remaining
    ]


class DiscreteState
  ###::
    name: symbol
  ###
  constructor: (symbolName ###: string###) ->
    @name = Symbol symbolName


class ActiveViewState extends DiscreteState
class ActiveFilterState extends DiscreteState


class ActiveSourceState extends DiscreteState


instantaneousStateSchema = (
    appStates ###: StateSet<ActiveViewState>###,
    sourcesHandle ###: () => StateSet<ActiveSourceState>###,
    filters ###: StateSet<ActiveFilterState>###
    ) ->
  view: appStates
  source: sourceGraph
  filter: filters


class DigitalInputState extends DiscreteState

class ContinuousState
  ###::
    minimum: number
    maximum: number
  ###

  constructor: (@minimum, @maximum) ->


class AnalogInputState extends ContinuousState


instantaneousInputSchema = (digital ###: StateSet<DigitalInputState>###, analog ###: StateSet<AnalogInputState>###) ->
  continuous: analog
  magnitude: null
  control: digital
