@flow

    assert = require 'assert'
    {PassThrough} = require 'stream'

    stringHash = require 'string-hash'
    {Map} = require 'immutable'

    {ProductKey, StringKey} = require '../util/collections'
    ###::
      import type {TypedKey, ProductElement, ProductElementSpecification} from '../util/collections'
    ###

# StateSource

    ###::
      interface StateSource<Input, Value> {
        sample(): Value;
        update(input: Input): void;
      }
    ###

    class NormalizedFloat
      ###::
        inner: number
      ###
      constructor: (@inner) ->
        assert.ok @inner >= 0
        assert.ok @inner <= 1

      extractNormalizedFloat: -> @inner

      @Zero: => new @ 0
      @One: => new @ 1

    class FloatRange
      ###::
        minimum: number
        maximum: number
        diff: number
      ###
      constructor: (@minimum, @maximum) ->
        assert.ok @maximum > @minimum
        @diff = @maximum - @minimum

      normalize: (input###: number###)###: NormalizedFloat### ->
        assert.ok input >= @minimum
        assert.ok input <= @maximum
        inner = (input - @minimum) / @diff
        new NormalizedFloat inner

    class ContinuousInput ###::implements StateSource< number, NormalizedFloat >###
      ###::
        range: FloatRange
        value: NormalizedFloat
      ###
      constructor: (@range, @value = NormalizedFloat.Zero()) ->

      sample: ()###: NormalizedFloat### -> @value

      update: (newInput###: number###) ->
        @value = @range.normalize newInput
        undefined

Then we define a `DigitalValue` as a union of literal types.

    ###::
      export type DigitalValue = 'keycode-down' | 'keycode-up'
    ###

    # TODO: implement this! Note that it will have to assert or ensure that only one of the digital
    # inputs will ever be on at a time!
    # class DigitalToAnalogSpreader ###::implements StateSource< NormalizedFloat >###
    #   ###::
    #     range: FloatRange
    #     orderedInputs: Array< DigitalInput >
    #   ###
    #   constructor: (@range, @orderedInputs) ->
    #     assert.ok @orderedInputs.length > 0

# InputMapping

    class InputMapping
      ###::
        mapping: Map< ProductKey< FilterName >, InputAxisNode >
      ###
      constructor: (mapping###: ?Map< ProductKey< FilterName >, InputAxisNode >### = new Map) ->
        @mapping = mapping

# InputControlsSpecification
Separate from [`InputMapping`](#inputmapping) -- this describes the *View's* intrinsic input *requirements*, while `InputMapping` describes how the real analog/digital inputs match up to the declared inputs for each `View`!

    class InputSpecId extends StringKey

    ###::
      export interface InputSpec< T > {
        specId: InputSpecId;
        defaultValue: ?T;
      }
    ###

    class ContinuousInputSpec ###:: implements InputSpec< NormalizedFloat >###
      ###::
        specId: InputSpecId
        defaultValue: ?NormalizedFloat
      ###
      constructor: (specId###: InputSpecId###, defaultValue###: ?NormalizedFloat### = null) ->
        @specId = specId
        @defaultValue = defaultValue

    class DigitalInputSpec ###:: implements InputSpec< DigitalValue >###
      ###::
        specId: InputSpecId
        defaultValue: ?DigitalValue
      ###
      constructor: (specId###: InputSpecId###, defaultValue###: ?DigitalValue###) ->
        @specId = specId
        @defaultValue = defaultValue

    class InputControlsSpecification
      ###::
        specs: Array< InputSpec< any > >
      ###
      constructor: (specs###: Array< InputSpec< any > >###) ->
        @specs = specs

      @Empty: => new @ []

# InputRegistry

    class UnmappedKeypressError extends Error
      ###::
        unmappedKey: DiscreteInputEvent
      ###
      constructor: (unmappedKey###: DiscreteInputEvent###) ->
        super "key #{unmappedKey} was not mapped!"
        @unmappedKey = unmappedKey

    class Kbd
      ###::
        keys: string
      ###
      constructor: (@keys) ->
        assert.ok keys.length is 1

    ###::
      type InputRegistryEntry = InputRegistry | InputEventsStream

      type _mapping< K: TypedKey, V> = Map< ProductKey < K >, V >
    ###

    class InputRegistry
      ###::
        mapping: _mapping<DiscreteInputEvent, InputRegistryEntry>
      ###
      constructor: (previous###: InputRegistry | any###) ->
        @mapping = if previous?.constructor is InputRegistry then previous.mapping else previous

      merge: (other###: InputRegistry###)###: InputRegistry### ->
        new InputRegistry (@mapping.merge other.mapping)

      acceptKeyEvent: (keyCode###: DiscreteInputEvent###)###: ?InputRegistry### ->
        entry = @mapping.get(new ProductKey keyCode) ? throw new UnmappedKeypressError keyCode
        switch entry.constructor
          when InputRegistry then entry
          when InputEventsStream
            entry.write keyCode
            null
          else throw entry

      # registerKeystroke: (kbd###: Kbd###, dispatch###: (RegistryOperation) => void###)###: InputEventsStream### ->
      #   [keyDown, keyUp] = DiscreteInputEvent.keypressPairFromKbd kbd
      #   downKey = new ProductKey keyDown
      #   upKey = new ProductKey keyUp

      #   downRegistry = if @mapping.has downKey
      #     maybeRegistry = @mapping.get downKey
      #     assert.ok maybeRegistry::constructor is InputRegistry
      #     maybeRegistry
      #   else
      #     newDownRegistry = new InputRegistry
      #     dispatch new UpdateRegistryBindings new InputRegistry new Map [[downKey, newDownRegistry]]
      #     newDownRegistry

      #   upStream = if downRegistry.has upKey
      #     maybeStream = downRegistry.get upKey
      #     assert.ok maybeStream::constructor is InputEventsStream
      #     maybeStream
      #   else
      #     newUpStream = new InputEventsStream
      #     (downRegistry.set upKey, new InputEventsStream).get upKey

      #   upStream

## RegistryOperation

    ###::
      export interface RegistryOperation {
        invoke(registries: RegistryForInputRegistries): RegistryForInputRegistries;
      }
    ###

    class Keypress ###:: implements RegistryOperation###
      ###::
        event: DiscreteInputEvent
      ###
      constructor: (event###: DiscreteInputEvent###) -> @event = event

      invoke: (registry###: InputRegistry###)###: InputRegistry### ->
        registry.acceptKeyEvent(@event) ? new InputRegistry

    class UpdateRegistryBindings ###:: implements RegistryOperation###
      ###::
        source: Symbol
        newRegistry: InputRegistry
      ###
      constructor: (source###: Symbol###, newRegistry###: InputRegistry###) ->
        @source = source
        @newRegistry = newRegistry

      invoke: (registry###: InputRegistry###)###: InputRegistry### ->
        registry.merge @newRegistry

## DiscreteInputEvent

    ###::
      type _inputEventOpts = {|
        key: string,
        keyValue?: ?DigitalValue,
        ctrlPressed?: ?boolean,
        metaPressed?: ?boolean,
        shiftPressed?: ?boolean,
      |}
    ###

    class DiscreteInputEvent ###:: implements TypedKey###
      ###::
        key: string
        keyValue: DigitalValue
        ctrlPressed: boolean
        metaPressed: boolean
        shiftPressed: boolean
      ###
      constructor: (opts###: _inputEventOpts###) ->
        {key, keyValue = DigitalValue.Down(), ctrlPressed = no, metaPressed = no, shiftPressed = no} = opts
        @key = key
        @keyValue = keyValue
        @ctrlPressed = ctrlPressed
        @metaPressed = metaPressed
        @shiftPressed = shiftPressed

      productElements: ()###: ProductElementSpecification### -> @

      @keypressPairFromKbd: (kbd###: Kbd###)###: [DiscreteInputEvent, DiscreteInputEvent]### =>
        keyDown = new @ {key: kbd.keys, keyValue: DigitalValue.Down()}
        keyUp = new @ {key: kbd.keys, keyValue: DigitalValue.Up()}
        [keyDown, keyUp]

      @fromKeyboardEvent: (event###: KeyboardEvent###, keyValue###: DigitalValue###)###: DiscreteInputEvent### =>
        {key, ctrlKey: ctrlPressed, metaKey: metaPressed, shiftKey: shiftPressed} = event
        new @ key, ctrlPressed, metaPressed, shiftPressed, keyValue

## InputEventsStream

    class InputEventsStream extends PassThrough
      ###::
        exclusiveListener: ?(DiscreteInputEvent) => void
      ###
      constructor: ->
        super objectMode: yes
        @exclusiveListener = null

      subscribeExclusive: (fn###: (DiscreteInputEvent) => void###) ->
        @unsubscribeRemaining()
        @exclusiveListener = fn
        @addListener 'data', fn

      unsubscribeRemaining: ->
        @removeListener 'data', @exclusiveListener if @exclusiveListener?

# Exports

    module.exports = {
      InputMapping, InputControlsSpecification, DigitalInput, DigitalValue,
      InputRegistry, DiscreteInputEvent, InputEventsStream, Keypress, UpdateRegistryBindings,
      ContinuousInputSpec, DigitalInputSpec,
    }
