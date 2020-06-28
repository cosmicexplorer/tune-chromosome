@flow

    assert = require 'assert'


# Utils
TODO: Maybe upstream these into lodash!!!??


    splitArrayAt = ###::<T>###(arr ###: Array<T>###, i ###: number###) ###: [Array<T>, Array<T>]### ->
      assert.ok i > 0
      assert.ok i < arr.length
      left = arr[..i]
      right = arr[i..]
      [left, right]

    # TODO: generic memoize function here!!
    # memoize = ###::<Fn>### (fn###: Fn###)###: ###


# Resource

We would prefer to uses an `interface Resource`, but that causes Flow to blow up when trying to use the interface `Resource` as a trait bound elsewhere.

    class Resource


    class NullResource extends Resource

    class FilterRequest extends Resource

    class InputSetRequest extends Resource

    class FilterParameterRequest extends Resource
      ###::
        selectedInputs: InputSet
      ###
      constructor: (@selectedInputs) ->
        super()


# InputControlsSpecification
Separate from [`InputMapping`](#inputmapping) -- this describes the *View's* intrinsic input *requirements*, while `InputMapping` describes how the real analog/digital inputs match up to the declared inputs for each `View`!


    class InputControlsSpecification

# StateChangeResult

    class StateChangeResult ###::< Product >###
      ###::
        product: Product
        state: AppState
      ###
      constructor: (product###: ?Product###, @state) ->

`@product` can have `null` or `undefined` as a legitimate value, which it's not clear how to represent in Flow right now without requiring a ton of type-casting whenever `@product` is dereferenced. So we just do it once here.

        @product = (product###: any###)

# Views

    ###::
      interface View< Res: Resource, Product > {
        provides(): Class< Res >;
        switchTo(request: Res): Promise< Product >;
      }
    ###


## Main

    class Main ###:: implements View< NullResource, null >###
      provides: -> NullResource

Pass in the state without modification, *ignore* the request, and return undefined.

      switchTo: ->
        await return null


## FilterSelect


    class FilterSelect ###:: implements View< FilterRequest, FilterNode >###
      provides: -> FilterRequest

We similarly ignore the `request` here, as `FilterRequest` has no useful information in it at this time.

      switchTo: (_request) ->
        # TODO: return something other than the Silence filter!!!
        await return Silence


## SelectInput


    class DigitalKey extends InputAxis


    class SelectInput ###:: implements View< InputSetRequest, InputSet >###
      provides: -> InputSetRequest
      switchTo: ->
        await return new InputSet [
          new InputAxisNode
            name: 'digital-key'
            axis: new DigitalKey
            filterParameter: null
        ]


## SelectFilterParameter


    class SelectFilterParameter ###:: implements View< FilterParameterRequest, RemapResult >###
      provides: -> FilterParameterRequest
      switchTo: ({selectedInputs}) ->

        assert.equal 1, selectedInputs.axes.length
        [axisNode] = selectedInputs.axes

        assert.ok not axisNode.filterParameter?

        mappedAxisNode = new InputAxisNode
          name: axisNode.name
          axis: axisNode.axis
          # TODO: actually add logic to choose a specific FilterParameter here!!
          filterParameter: new FilterParameter

        newMapping = new InputMapping {[mappedAxisNode.name]: mappedAxisNode}

        await return new RemapResult newMapping

    class RemapResult
      ###::
        inputMapping: InputMapping
      ###
      constructor: (@inputMapping) ->


# Filters
`Filter`s have controls and convert an input stream to an output stream!

**Filters represent "the state of making and iterating on a sound" as atomically as possible.** By selecting a filter, the user should be able to:
1. immediately hear the exact sound they heard before when last playing the filter, and
2. immediately have the ability to use the exact same InputMapping as when last playing the filter!

Contrast to [`AppState`](#appstate)!


    class Filter
      ###::
        inputMapping: InputMapping
      ###
      constructor: (@inputMapping) ->


A `FilterNode` is a wrapper for a node in a vast searchable graph of all `Filter`s! This means it contains the information required to effectively index and search filters later, in the finely-tuned `filter-select` view. It will also need to contain sufficient information to allow for `select-filter-parameter` to traverse nodes efficiently.


    _filterNodeSeparator = '/'

    ###::
      interface FilterNodeAgglomeration {}

      type _pipeOptions = {
        source: FilterNode,
        output: FilterNode,
        name?: ?string,
      }

      type _pipedSourceOutput = {
        source: FilterNode,
        output: FilterNode,
      }
    ###

- `name` contains a reference to the entire prototype chain of filters for fuzzy matching at the speed of thought (like emacs buffer searching by name with helm!!!).
    - `name` can also be set afterwards to "pin" or "save" specific filters with short abbreviations.
- `source` and `output` allow traversing sources step by step by walking "between" them.
- `timestamp` enables time travel view (chronological search) through filters!

The `FilterNode` class follows:

    class FilterNode
      ###::
        filter: Filter
        name: string
        source: ?FilterNode
        output: ?FilterNode
        timestamp: Date
      ###
      constructor: ({@filter, @name, @source, @output, @timestamp}) ->


Retrieve the `source` and `output` nodes after asserting that they exist (i.e. that this FilterNode is "active" and has a specified input and output stream).

      assertPipedSourceOutput: ###: _pipedSourceOutput### ->
        assert.ok @source?
        assert.ok @output?

We cast through any to satisfy Flow here. See https://flow.org/en/docs/types/casting/#toc-type-casting-through-any.

        {source, output} = {@source, @output}
        source2 = (source###: any###)
        output2 = (output###: any###)
        {source: source2, output: output2}

      pipe: (options###: _pipeOptions###) ###: FilterNode### ->
        {source, output, name = null} = options

Immediately after selecting a filter, we expect the node we receive to have been sanitized of input and output. The input and output is **controlled by the user**, *elsewhere!*

        assert.ok not @source?
        assert.ok not @output?

        new FilterNode
          filter: @filter
          name: name ? @name
          source: source
          output: output
          timestamp: new Date

      remap: (inputMapping###: InputMapping###)###: FilterNode### ->
        throw new Error("TODO: unimplemented!!!")


# Input{Axis,Set,Mapping}

    class InputAxis

    class InputAxisNode
      ###::
        name: string
        axis: InputAxis
        filterParameter: ?FilterParameter
      ###
      constructor: ({@name, @axis, @filterParameter = null}) ->

    class InputSet
      ###::
        axes: Array< InputAxisNode >
      ###
      constructor: (@axes) ->

      isEmpty: -> @axes.length is 0

      @Empty: => new @ []


## FilterParameter
This class points somewhere into some nested FilterNode and into a setting on its contained Filter. Note that a Filter will have its own InputMapping as well. **RECURSION!**


    class FilterParameter

    class InputMapping
      ###::
        mapping: {[string]: InputAxisNode}
      ###
      constructor: (@mapping) ->

    Silence = new FilterNode
      filter: new Filter new InputMapping {}
      name: ''
      source: null
      output: null
      timestamp: new Date


**Filters are a "sound state", and FilterNodes are an index into a field (TODO: a math field????) to traverse sound states!!!!**


# StateSet


    class StateSet ###::< T >###
      ###::
        states: Array< T >
      ###
      constructor: (@states) ->

      extractDimensions: (numDimensions ###: number###) ###: [StateSet< T >, StateSet< T >]### ->
        assert.ok numDimensions > 0
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
        name: string
      ###
      constructor: (@name) ->


    class ActiveViewState extends DiscreteState

    class ActiveFilterState extends DiscreteState

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
        digital: StateSet< DigitalInputState >
      ###
      constructor: (@digital, minimum, maximum) ->
        super minimum, maximum



# AppState
**`AppState` represents the state of the entire application, such that it can be precisely reconstructed later, upon app startup, to drop the user into the exact same visuals, input mapping, and view.** This is in contrast to [`Filter`s](#filters), which represent just the state of a particular sound being iterated on at some point (this is intentionally decoupled from app state).


    class AppState
      ###::
        activeFilterNode: FilterNode
        activeView: any
        // TODO: Figure out a more type-safe way to represent this run-time type-indexed map!
        resourceMapping: { [Function]: any }
      ###
      constructor: (@activeFilterNode, @activeView, @resourceMapping) ->

      requestResource: ###::< Res: Resource, Prod >### (resource###: Res###) ###: Promise< StateChangeResult< Prod > >### ->
        nextView = @resourceMapping[Object.getPrototypeOf resource]

        result = await nextView.switchTo resource

        prototypeChainState = Object.create @

        prototypeChainState.activeView = nextView

        return new StateChangeResult result, prototypeChainState



# Operations

"Operations" are defined to be the impetus by which the app moves through its [views](#views).


    ###::
      interface Operation {
        invoke(state: AppState): Promise< AppState >;
      }
    ###

## Append
The "append" operation will trigger a move to the `filter-select` view. Upon returning, the previously active filter is piped into the newly-selected filter.

- **Note:** rearranges and/or clobbers the $M!$ mapping!
- **TODO:** make the "rearrangement" of $M!$ as natural as possible!
  - Map (in an extremely stable priority order) any free variables to inputs of the new filter!
    - **TODO:** this sounds like it's still decomposable into separate operations for now, but it sure *sounds* a lot like the "Affix/Remap" operation!'

The `Append` class follows:


    class Append ###:: implements Operation###
      invoke: (state) ->
        {activeFilterNode} = state

        {product: selectedFilterNode, state} = await state.requestResource ###::< _, FilterNode >### (new FilterRequest)


Immediately after selecting a filter, we expect the node we receive to have been sanitized of input and output. The input and output is controlled by the *user*, *elsewhere*!


        newName = "#{activeFilterNode.name}#{_filterNodeSeparator}#{selectedFilterNode.name}"

        {output} = activeFilterNode.assertPipedSourceOutput()
        combinedNode = selectedFilterNode.pipe
          source: activeFilterNode
          output: output
          name: newName


It's still **absolutely bonkers** to me that we can just *mutate* `state.activeFilterNode` here, then expect that because `state.requestResource()` will internally call `Object.create @`, we can just let it go forward on its merry way (not modifying any other states, creating a little sandbox of sorts!!)! We've invented react.js again!!!


        state.activeFilterNode = combinedNode

        {state} = await state.requestResource new NullResource
        return state


## Select

    class Select ###:: implements Operation###
      invoke: (state) ->
        {activeFilterNode} = state
        {source, output} = activeFilterNode.assertPipedSourceOutput()

Note how here, the variable `state` is both dereferenced and assigned to in a single statement. CoffeeScript's destructuring powers can enable this **effortlessly fluent stateful programming!!!**.


        {product: selectedFilterNode, state} = await state.requestResource ###::< _, FilterNode >### (new FilterRequest)


Here again, we can modify the state, then ask it to send us home.


        state.activeFilterNode = selectedFilterNode.pipe {source, output}

        {state} = await state.requestResource new NullResource
        return state


## Undo

Extremely similar to `Select`, but simply follows the `.source` field from the active `FilterNode`. Note that `source` and `output` form a doubly-linked list of `FilterNode`s.

    class Undo ###:: implements Operation###
      invoke: (state) ->
        {activeFilterNode: {source}} = state

        throw new Error("TODO: undo without a previous filter") unless source?

        state.activeFilterNode = source

        {state} = await state.requestResource new NullResource
        return state

TODO: implement redo!


## AffixRemap


    class AffixRemap ###:: implements Operation###
      invoke: (state) ->
        {product: selectedInput, state} = await state.requestResource ###::< _, InputSet >### (new InputSetRequest)

        {product: {inputMapping: remapResult}, state} = (
          await state.requestResource ###::< _, RemapResult >### (new FilterParameterRequest selectedInput))

        state.activeFilterNode = state.activeFilterNode.remap remapResult

        {state} = await state.requestResource new NullResource
        return state
