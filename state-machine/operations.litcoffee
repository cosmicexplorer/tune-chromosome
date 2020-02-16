    # @flow

    assert = require 'assert'


# Resources


    class Resource


    class NullResource extends Resource

    class FilterResource extends Resource

    class InputResource extends Resource

    class FilterParameterResource extends Resource


# InputControlsSpecification
Separate from [`InputMapping`](#inputmapping) -- this describes the *View's* intrinsic input *requirements*, while `InputMapping` describes how the real analog/digital inputs match up to the declared inputs for each `View`!


    class InputControlsSpecification


# StateChange{Request,Result}


    class StateChangeRequest
      ###::
        request: Resource
        state: AppState
      ###
      constructor: (@request, @state) ->


    class StateChangeResult ###::<Product>###
      ###::
        product: Product
        state: AppState
      ###
      constructor: (product###: ?Product###, @state) ->
        `let product2 = ((product/*: any*/)/*: Product*/);`
        @product = product2


# Views


    ###::
      interface View<Product> {
        provides(): Class<Resource>;
        switchTo(request: StateChangeRequest): Promise<StateChangeResult<Product>>;
      }
    ###


## Main
Pass in the state without modification, *ignore* the request, and return undefined.


    class Main ###:: implements View<null>###
      provides: -> NullResource
      switchTo: ({state}) ->
        state.activeView = @
        await return new StateChangeResult null, state


## FilterSelect
We similarly ignore the `request` here, as `FilterResource` has no useful information in it at this time.


    class FilterSelect ###:: implements View<FilterNode>###
      provides: -> FilterResource
      switchTo: ({state}) ->
        await throw new Error("not implemented yet! state was: #{JSON.stringify state}")


## SelectInput


    class SelectInput ###:: implements View<InputSet>###
      provides: -> InputResource
      switchTo: ({state}) ->
        await throw new Error("not implemented yet! state was: #{JSON.stringify state}")


## SelectFilterParameter


    class SelectFilterParameter ###:: implements View<FilterParameterResult>###
      provides: -> FilterParameterResource
      switchTo: ({state}) ->
        await throw new Error("not implemented yet! state was: #{JSON.stringify state}")

    class FilterParameterResult


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

    getSymbolName = (s###: symbol###)###: string### -> s.toString().replace /^Symbol\(|\)$/g, ''


    ###::
      interface FilterNodeAgglomeration {
      }


      type _pipeOptions = {
        source: FilterNode,
        output: FilterNode,
        name?: ?symbol,
      }
    ###


    class FilterNode
      ###::
        filter: Filter
        // Contains a reference to the entire prototype chain of filters for fuzzy matching at the speed of thought (like emacs buffer searching by name with helm!!!).
        name: symbol
        // `source` and `output` allow traversing sources step by step by walking "between" them.
        source: ?FilterNode
        output: ?FilterNode
        // Enable time travel view (chronological search) through filters!
        timestamp: Date
      ###
      constructor: ({@filter, @name, @source, @output, @timestamp}) ->

      symbolName: -> getSymbolName @name

      pipe: (options###: _pipeOptions###) ###: FilterNode### ->
        {source, output, name = null} = options


Immediately after selecting a filter, we expect the node we receive to have been sanitized of input and output. The input and output is controlled by the *user*, *elsewhere*!


        assert.ok not @source?
        assert.ok not @output?

        new FilterNode
          filter: @filter
          name: name ? @name
          source: source
          output: output
          timestamp: new Date


**Filters are a "sound state", and FilterNodes are an index into a field (a math field????) to traverse sound states!!!!**


# Input{Axis,Mapping}


    ###::
      interface InputAxis {
      }
    ###


    class InputSet
      ###::
        axes: Array<InputAxis>
      ###
      constructor: (@axes) ->

      isEmpty: -> @axes.length is 0

      @Empty: => new @ []


    class InputMapping


# StateSet


    # FIXME: Upstream this into lodash!!!
    splitArrayAt = ###::<T>###(arr ###: Array<T>###, i ###: number###) ###: [Array<T>, Array<T>]### ->
      assert.ok i > 0
      assert.ok i < arr.length
      left = arr[..i]
      right = arr[i..]
      [left, right]


    class StateSet ###::<T>###
      ###::
        states: Array<T>
      ###
      constructor: (@states) ->

      extractDimensions: (numDimensions ###: number###) ###: [StateSet<T>, StateSet<T>]### ->
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
        name: symbol
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
        digital: StateSet<DigitalInputState>
      ###
      constructor: (@digital, minimum, maximum) ->
        super minimum, maximum



# AppState
**`AppState` represents the state of the entire application, such that it can be precisely reconstructed later, upon app startup, to drop the user into the exact same visuals, input mapping, and view.** This is in contrast to [`Filter`s](#filters), which represent just the state of a particular sound being iterated on at some point (this is intentionally decoupled from app state).


    class AppState
      ###::
        activeFilterNode: FilterNode
        activeInputMapping: InputMapping
        activeView: View<any>
        // TODO: Figure out a more type-safe way to represent thiss type-indexed map!
        resourceMapping: { [Function]: View<any> }
      ###
      constructor: (@activeFilterNode, @activeInputMapping, @activeView, @resourceMapping) ->

Assert that keys of `@resourceMapping` are legitimate type objects subclassing Resource.

        for own k, _ of @resourceMapping
          assert.equal Resource, Object.getPrototypeOf k
        true

      requestResource: ###::<Product>### (resource###: Resource###) ###: Promise<StateChangeResult<Product>>### ->
        nextView = @resourceMapping[Object.getPrototypeOf resource]

        prototypeChainState = Object.create @

        return await nextView.switchTo new StateChangeRequest resource, prototypeChainState



# Operations

"Operations" are defined to be the impetus by which the app moves through its [views](#views).


    ###::
      interface Operation {
        invoke(state: AppState): Promise<AppState>;
      }
    ###


## Append
The "append" operation will trigger a move to the `filter-select` view. Upon returning, the previously active filter is piped into the newly-selected filter.

- **Note:** rearranges and/or clobbers the $M!$ mapping!
- **TODO:** make the "rearrangement" of $M!$ as natural as possible!
  - Map (in an extremely stable priority order) any free variables to inputs of the new filter!
    - **TODO:** this sounds like it's still decomposable into separate operations for now, but it sure *sounds* a lot like the "Affix/Remap" operation!'


    class Append ###:: implements Operation###
      invoke: (state) ->
        {activeFilterNode} = state
        `
        let source2 = ((activeFilterNode.source/*: any*/)/*: FilterNode*/);
        let output2 = ((activeFilterNode.output/*: any*/)/*: FilterNode*/);
        `
        {product: selectedFilterNode, state} = await state.requestResource ###::<FilterNode>### (new FilterResource)


Immediately after selecting a filter, we expect the node we receive to have been sanitized of input and output. The input and output is controlled by the *user*, *elsewhere*!


        newName = "#{activeFilterNode.symbolName()}#{_filterNodeSeparator}#{selectedFilterNode.symbolName()}"

        combinedNode = selectedFilterNode.pipe
          source: source2
          output: output2
          name: Symbol newName


It's still **absolutely bonkers** to me that we can just *mutate* `state.activeFilterNode` here, then expect that because `state.requestResource()` will internally call `Object.create @`, we can just let it go forward on its merry way (not modifying any other states, creating a little sandbox of sorts!!)! We've invented react.js again!!!


        state.activeFilterNode = combinedNode

        {state} = await state.requestResource new NullResource
        return state


## Select


    class Select ###:: implements Operation###
      invoke: (state) ->
        {activeFilterNode} = state
        `
        let source2 = ((activeFilterNode.source/*: any*/)/*: FilterNode*/);
        let output2 = ((activeFilterNode.output/*: any*/)/*: FilterNode*/);
        `

Note how here, the variable `state` is both dereferenced and assigned to in a single statement. CoffeeScript's destructuring powers can enable this effortlessly fluent **stateful programming!!!**.


        {product: selectedFilterNode, state} = await state.requestResource ###::<FilterNode>### (new FilterResource)

        pipedNode = selectedFilterNode.pipe
          source: source2
          output: output2


Here again, we can modify the state, then ask it to send us home.


        state.activeFilterNode = pipedNode

        {state} = await state.requestResource new NullResource
        return state
