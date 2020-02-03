# @flow

assert = require 'assert'
fs = require 'fs'

# FIXME: Upstream this into lodash!!!
splitArrayAt = ###::<T>###(arr ###: Array<T>###, i ###: number###) ###: [Array<T>, Array<T>]### ->
  assert.ok i < arr.length
  left = arr[..i]
  right = arr[i..]
  [left, right]

###
internalState|externalState
:-----------:|:-----------:
v!             u! (analog!!!)
s!             m! (analog, or digital-analog-converter?)
f!             c! ({1,0} x 12???)
###

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

    [left, right] = splitArrayAt @states, numDimensions
    # TODO: figure out some way of making using of the prototype chain here??? flow gets mad at
    # naive Object.create() invocations >=[
    [
      new StateSet states: left
      new StateSet states: right
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

class DigitalInputState extends DiscreteState

class ContinuousState
  ###::
    minimum: number
    maximum: number
  ###

  constructor: (@minimum, @maximum) ->

class AnalogInputState extends ContinuousState

class DigitalToAnalogSpreader extends ContinuousState
  ###::
    digital: StateSet<DigitalInputState>
  ###

  constructor: (@digital, minimum, maximum) ->
    super minimum, maximum

class InstantaneousAppState
  ###::
    viewState: StateSet<ActiveViewState>
    sourceState: StateSet<ActiveSourceState>
    filterState: StateSet<ActiveFilterState>
    fluidInputStream: StateSet<AnalogInputState>
    magnitudeInputStream: StateSet<AnalogInputState>
    controlInputStream: StateSet<DigitalInputState>
  ###
  constructor: ({@viewState, @sourceState, @filterState,
                 @fluidInputStream, @magnitudeInputStream, @controlInputStream}) ->
