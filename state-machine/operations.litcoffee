@flow

This `require()` call is needed for any file that uses coroutines to polyfill for the browser!

    require 'regenerator-runtime/runtime'

    assert = require 'assert'
    stringHash = require 'string-hash'
    {v4: uuidv4} = require 'uuid'

    {Filter, FilterNode} = require '../audio/filter-chain'
    {DiscreteInputEvent, InputMapping, InputControlsSpecification, InputRegistry} = require '../input/input'

    {TypedMap} = require '../util/collections'
    ###::
      import type {TypedKey} from '../util/collections'
    ###

# Resource

    class Resource

    class NullResource extends Resource

    class FilterRequest extends Resource

    class InputSetRequest extends Resource

    class FilterParameterRequest extends Resource
      ###::
        selectedInputs: InputSet
      ###
      constructor: (selectedInputs###: InputSet###) ->
        super()
        @selectedInputs = selectedInputs

# StateChangeResult

    class StateChangeResult ###::< Product >###
      ###::
        product: Product
        state: AppState
      ###
      constructor: (product###: ?Product###, @state) ->
        @product = (product###: any###)

# View

    class View
      ###::
        inputSpec: InputControlsSpecification
      ###
      constructor: (@inputSpec = InputControlsSpecification.Empty()) ->

## Main

    class Main extends View

## FilterSelect

    class FilterSelect extends View

## SelectInput

    class SelectInput extends View

## SelectFilterParameter

    class SelectFilterParameter extends View

## RemapResult

    class RemapResult
      ###::
        inputMapping: InputMapping
      ###
      # $FlowFixMe
      constructor: (@inputMapping) ->

## Silence

    Silence = new FilterNode
      filter: new Filter new InputMapping new TypedMap
      name: ''
      source: null
      output: null
      timestamp: new Date

# AppState
**`AppState` represents the state of the entire application, such that it can be precisely reconstructed later, upon app startup, to drop the user into the exact same visuals, input mapping, and view.** This is in contrast to [`Filter`](../audio/filter-chain.html#filter)s, which represent just the state of a particular sound being iterated on at some point (this is intentionally decoupled from app state).

    class AppState
      ###::
        activeFilterNode: FilterNode
        activeView: View
        activeResource: Resource
      ###
      constructor: (activeFilterNode###: FilterNode###, activeView###: View< any, any >###) ->
        @activeFilterNode = activeFilterNode
        @activeView = activeView
        @activeResource = (null###: any###)

      requestResource: ###::< Res: Resource, Prod >### (resource###: Res###) ###: Promise< StateChangeResult< Prod > >### ->
        # Ensure this method is only ever run a single time per resource request.
        assert.ok not @resourceMapping.has resource

        nextView = switch resource.constructor
          when NullResource then new Main
          when FilterRequest then new FilterSelect
          when InputSetRequest then new SelectInput
          when FilterParameterRequest then new SelectFilterParameter
          else throw resource

NB: This is very complex logic to convert a callback into a Promise!! See comments.

        getResult = new Promise (resolve, reject) =>

This method will take a callback, and right before the callback is executed, delete the entry corresponding to `resource` from `@resourceMapping`.

          wrapCallback = (cb) => (args...) =>
            @resourceMapping.delete resource
            cb args...

Before returning execution back to the body of `requestResource`, add the `resolve` and `reject` methods to `@resourceMapping`.

          @resourceMapping.set resource, [wrapCallback(resolve), wrapCallback(reject)]
          undefined

NB: Creating a new object with `Object.create()` is necessary for `.setAppState()` to register a changed state!

        prototypeChainObject = Object.create @
        prototypeChainObject.activeView = nextView
        prototypeChainObject.activeResource = resource

Await the promise created above, which will be triggered asynchronously by UI interactions which extract the `[resolve, reject]` method pair from `@resourceMapping`.

        result = (await getResult###: Prod###)

        return new StateChangeResult result, prototypeChainObject

# Operator

"Operators" are defined to be the impetus by which the app moves through its [views](#views).

    ###::
      interface Operator {
        invoke(state: AppState): Promise< AppState >;
      }
    ###

## Append
The "append" operation will trigger a move to the `filter-select` view. Upon returning, the previously active filter is piped into the newly-selected filter.

- **Note:** rearranges and/or clobbers the $M!$ mapping!
- **TODO:** make the "rearrangement" of $M!$ as natural as possible!
  - Map (in an extremely stable priority order) any free variables to inputs of the new filter!
    - **TODO:** this sounds like it's still decomposable into separate operations for now, but it sure *sounds* a lot like the "Affix/Remap" operation!'

# The `Append` class follows:

    class Append ###:: implements Operator###
      invoke: (state###: AppState###, dispatch###: (Operator) => void###)###: Promise< AppState >### ->
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

    class Select ###:: implements Operator###
      invoke: (state###: AppState###)###: Promise< AppState >### ->
        {activeFilterNode} = state
        {source, output} = activeFilterNode.assertPipedSourceOutput()

Note how here, the variable `state` is both dereferenced and assigned to in a single statement. CoffeeScript's destructuring powers can enable this **effortlessly fluent stateful programming!!!**.

        {product: selectedFilterNode, state} = await state.requestResource ###::< _, FilterNode >### (new FilterRequest)

Here again, we can modify the state, then ask it to send us home.

        state.activeFilterNode = selectedFilterNode.pipe {source, output}

        {state} = await state.requestResource new NullResource
        return state

## Undo/Redo
TODO: implement undo/redo!

## AffixRemap

    class AffixRemap ###:: implements Operator###
      invoke: (state###: AppState###)###: Promise< AppState >### ->
        # TODO: reverse this logic -- we will want to select the FilterParameter first, *then* the input control to map it to!!
        {product: selectedInput, state} = await state.requestResource ###::< _, InputSet >### (new InputSetRequest)

        {product: {inputMapping: remapResult}, state} = (
          await state.requestResource ###::< _, RemapResult >### (new FilterParameterRequest selectedInput))

        state.activeFilterNode = state.activeFilterNode.remap remapResult

        {state} = await state.requestResource new NullResource
        return state

# Exports

    module.exports = {
      Main, FilterSelect, SelectInput, SelectFilterParameter, AppState, Silence,
      Resource, NullResource, FilterRequest, InputSetRequest, FilterParameterRequest, Select,
      InputMapping, Filter, FilterNode, Keypress, UnmappedKeypressError,
    }
