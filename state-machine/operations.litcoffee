@flow

    require 'regenerator-runtime/runtime'

    assert = require 'assert'
    stringHash = require 'string-hash'
    {v4: uuidv4} = require 'uuid'

    {TypedMap} = require '../util/collections'
    ###::
      import type {TypedKey} from '../util/collections';
    ###
    {classOf} = require '../util/util'


# Resource

We would prefer to use an `interface Resource`, but that causes Flow to blow up when trying to use the interface `Resource` as a trait bound elsewhere.

    ###::
      export type SetAppStateCallback = (AppState) => void;
    ###

    class Resource###:: implements TypedKey###
      ###::
        setAppState: SetAppStateCallback
        uuid: string
      ###
      constructor: (setAppState###: SetAppStateCallback###) ->
        @setAppState = setAppState
        @uuid = uuidv4()

      computeHash: -> stringHash @uuid

    class NullResource extends Resource

    class FilterRequest extends Resource

    class InputSetRequest extends Resource

    class FilterParameterRequest extends Resource
      ###::
        selectedInputs: InputSet
      ###
      constructor: (setAppState###: SetAppStateCallback###, selectedInputs###: InputSet###) ->
        super setAppState
        @selectedInputs = selectedInputs


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

TODO: add some functionality to the `View` interface?

    ###::
      interface View< Res: Resource, Product > {
      }
    ###


## Main

    class Main ###:: implements View< NullResource, null >###

## FilterSelect


    class FilterSelect ###:: implements View< FilterRequest, FilterNode >###


## SelectInput

    class InputAxis

    class DigitalKey extends InputAxis


    class SelectInput ###:: implements View< InputSetRequest, InputSet >###


## SelectFilterParameter


    class SelectFilterParameter ###:: implements View< FilterParameterRequest, RemapResult >###

    class RemapResult
      ###::
        inputMapping: InputMapping
      ###
      # $FlowFixMe
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
      # $FlowFixMe
      constructor: (@inputMapping) ->


A `FilterNode` is a wrapper for a node in a vast searchable graph of all `Filter`s! This means it contains the information required to effectively index and search filters later, in the finely-tuned `filter-select` view. It will also need to contain sufficient information to allow for `select-filter-parameter` to traverse nodes efficiently.


    _filterNodeSeparator = '/'

    ###::
      interface FilterNodeAgglomeration {}

      type _pipeOptions = {|
        source: FilterNode,
        output: FilterNode,
        name?: ?string,
      |}

      type _pipedSourceOutput = {|
        source: FilterNode,
        output: FilterNode,
      |}
    ###

- `name` contains a reference to the entire prototype chain of filters for fuzzy matching at the speed of thought (like emacs buffer searching by name with helm!!!).
    - `name` can also be set afterwards to "pin" or "save" specific filters with short abbreviations.
- `source` and `output` allow traversing sources step by step by walking "between" them.
- `timestamp` enables time travel view (chronological search) through filters!

The `FilterNode` class follows:

    ###::
      type _filterOpts = {|
        filter: Filter,
        name: string,
        source: ?FilterNode,
        output: ?FilterNode,
        timestamp: Date,
      |}
    ###

    class FilterNode
      ###::
        filter: Filter
        name: string
        source: ?FilterNode
        output: ?FilterNode
        timestamp: Date
      ###
      constructor: (opts###: _filterOpts###) ->
        {filter, name, source, output, timestamp} = opts
        @filter = filter
        @name = name
        @source = source
        @output = output
        @timestamp = timestamp


Retrieve the `source` and `output` nodes after asserting that they exist (i.e. that this FilterNode is "active" and has a specified input and output stream).

      assertPipedSourceOutput: ###: _pipedSourceOutput### ->
        # TODO: why would we assume these are correct???
        # assert.ok @source?
        # assert.ok @output?

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


    ###::
      type _inputAxisNodeOpts = {|
        name: string,
        axis: InputAxis,
        filterParameter?: ?FilterParameter,
      |}
    ###

    class InputAxisNode
      ###::
        name: string
        axis: InputAxis
        filterParameter: ?FilterParameter
      ###
      constructor: (opts###: _inputAxisNodeOpts###) ->
        {name, axis, filterParameter = null} = opts
        @name = name
        @axis = axis
        @filterParameter = filterParameter

    class InputSet
      ###::
        axes: Array< InputAxisNode >
      ###
      # $FlowFixMe
      constructor: (@axes) ->

      isEmpty: -> @axes.length is 0

      @Empty: => new @ []


## FilterParameter
This class points somewhere into some nested FilterNode and into a setting on its contained Filter. Note that a Filter will have its own InputMapping as well. **RECURSION!**


    class FilterParameter

    class FilterName###:: implements TypedKey###
      ###::
        name: string
      ###
      constructor: (name###: string###) ->
        @name = name

      computeHash: -> stringHash @name

    class InputMapping
      ###::
        mapping: TypedMap< FilterName, InputAxisNode >
      ###
      constructor: (mapping###: TypedMap< FilterName, InputAxisNode >###) ->
        @mapping = mapping

    Silence = new FilterNode
      filter: new Filter new InputMapping new TypedMap
      name: ''
      source: null
      output: null
      timestamp: new Date


**Filters are a "sound state", and FilterNodes are an index into a field (TODO: a math field????) to traverse sound states!!!!**

# AppState
**`AppState` represents the state of the entire application, such that it can be precisely reconstructed later, upon app startup, to drop the user into the exact same visuals, input mapping, and view.** This is in contrast to [`Filter`s](#filters), which represent just the state of a particular sound being iterated on at some point (this is intentionally decoupled from app state).

    ###::
      type _resourceMapping = TypedMap< Resource, [(any) => void, (any) => void] >
    ###

    class AppState
      ###::
        activeFilterNode: FilterNode
        activeView: View< any, any >
        activeResource: Resource
        resourceMapping: _resourceMapping
      ###
      constructor: (activeFilterNode###: FilterNode###, activeView###: View< any, any >###, resourceMapping###: _resourceMapping###) ->
        @activeFilterNode = activeFilterNode
        @activeView = activeView
        @activeResource = (null###: any###)
        @resourceMapping = resourceMapping

      requestResource: ###::< Res: Resource, Prod >### (resource###: Res###) ###: Promise< StateChangeResult< Prod > >### ->
        # Ensure this method is only ever run a single time per resource request.
        assert.ok not @resourceMapping.has resource

        nextView = switch classOf resource
          when NullResource then new Main
          when FilterRequest then new FilterSelect
          when InputSetRequest then new SelectInput
          when FilterParameterRequest then new SelectFilterParameter
          else throw resource

NB: This is very complex logic to convert a callback into a Promise!! See comments.

        getResult = new Promise (resolve, reject) =>

This method will take a callback, and when right before the callback is executed, delete the entry corresponding to `resource` from `@resourceMapping`.

          wrapCallback = (cb) => (args...) =>
            @resourceMapping.delete resource
            cb args...

Before returning execution back to the body of `requestResource`, add the `resolve` and `reject` methods to `@resourceMapping`.

          @resourceMapping.set resource, [
            wrapCallback(resolve),
            wrapCallback(reject),
          ]
          undefined

NB: Creating a new object with `Object.create()` is necessary for `.setAppState()` to register a changed state!

        prototypeChainObject = Object.create @
        prototypeChainObject.activeView = nextView
        prototypeChainObject.activeResource = resource
        resource.setAppState prototypeChainObject

Await the promise created above, which will be triggered asynchronously by UI interactions which extract the `[resolve, reject]` method pair from `@resourceMapping`.

        result = (await getResult###: Prod###)

        return new StateChangeResult result, prototypeChainObject


# Operations

"Operations" are defined to be the impetus by which the app moves through its [views](#views).

    ###::
      interface Operation {
        invoke(state: AppState, setAppState: SetAppStateCallback): Promise< AppState >;
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
      invoke: (state###: AppState###, setAppState###: SetAppStateCallback###)###: Promise< AppState >### ->
        {activeFilterNode} = state

        {product: selectedFilterNode, state} = await state.requestResource ###::< _, FilterNode >### (new FilterRequest setAppState)


Immediately after selecting a filter, we expect the node we receive to have been sanitized of input and output. The input and output is controlled by the *user*, *elsewhere*!


        newName = "#{activeFilterNode.name}#{_filterNodeSeparator}#{selectedFilterNode.name}"

        {output} = activeFilterNode.assertPipedSourceOutput()
        combinedNode = selectedFilterNode.pipe
          source: activeFilterNode
          output: output
          name: newName


It's still **absolutely bonkers** to me that we can just *mutate* `state.activeFilterNode` here, then expect that because `state.requestResource()` will internally call `Object.create @`, we can just let it go forward on its merry way (not modifying any other states, creating a little sandbox of sorts!!)! We've invented react.js again!!!


        state.activeFilterNode = combinedNode

        {state} = await state.requestResource new NullResource setAppState
        return state


## Select

    class Select ###:: implements Operation###
      invoke: (state###: AppState###, setAppState###: SetAppStateCallback###)###: Promise< AppState >### ->
        {activeFilterNode} = state
        {source, output} = activeFilterNode.assertPipedSourceOutput()

Note how here, the variable `state` is both dereferenced and assigned to in a single statement. CoffeeScript's destructuring powers can enable this **effortlessly fluent stateful programming!!!**.

        {product: selectedFilterNode, state} = await state.requestResource ###::< _, FilterNode >### (new FilterRequest setAppState)

Here again, we can modify the state, then ask it to send us home.

        state.activeFilterNode = selectedFilterNode.pipe {source, output}

        {state} = await state.requestResource new NullResource setAppState
        return state


## Undo/Redo
TODO: implement undo/redo!


## AffixRemap

    class AffixRemap ###:: implements Operation###
      invoke: (state###: AppState###, setAppState###: SetAppStateCallback###)###: Promise< AppState >### ->
        # TODO: reverse this logic -- we will want to select the FilterParameter first, *then* the input control to map it to!!
        {product: selectedInput, state} = await state.requestResource ###::< _, InputSet >### (new InputSetRequest setAppState)

        {product: {inputMapping: remapResult}, state} = (
          await state.requestResource ###::< _, RemapResult >### (new FilterParameterRequest setAppState, selectedInput))

        state.activeFilterNode = state.activeFilterNode.remap remapResult

        {state} = await state.requestResource new NullResource setAppState
        return state


    module.exports = {
      Main, FilterSelect, SelectInput, SelectFilterParameter, AppState, Silence,
      Resource, NullResource, FilterRequest, InputSetRequest, FilterParameterRequest, Select,
      InputMapping, Filter, FilterNode,
    }
