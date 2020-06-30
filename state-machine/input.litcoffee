@flow

    assert = require 'assert'

    {TypedMap} = require '../util/collections'

# StateSource

    ###::
      interface StateSource<Input, Value> {
        sample(): Value;
        update(input: Input): null;
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

      @Zero: -> @ 0
      @One: -> @ 1

    class FloatRange
      ###::
        minimum: number
        maximum: number
      ###
      constructor: (@minimum, @maximum) ->
        assert.ok @maximum > @minimum
        @diff = @maximum - @minimum

      normalize: (input###: number###)###: NormalizedFloat### ->
        assert.ok input >= @minimum
        assert.ok input <= @maximum
        inner = (input - @minimum) / @diff
        NormalizedFloat inner

    class ContinuousInput ###::implements StateSource< number, NormalizedFloat >###
      ###::
        range: FloatRange
        value: NormalizedFloat
      ###
      constructor: (@range, @value = NormalizedFloat.Zero()) ->

      sample: ()###: NormalizedFloat### -> @value

      update: (input###: number###) ->
        @value = @range.normalize newInput
        null

Then we define a `DigitalInput`.

    class DigitalValue
      ###::
        value: Symbol
      ###
      constructor: (@value) ->
        assert.ok (@value is DigitalValue._Down) or (@value is DigitalValue._Up)

      setValueFrom: (other###: DigitalValue###) ->
        @value = other.value
        null

      @_Down = new Symbol 'keycode-down'
      @_Up = new Symbol 'keycode-up'
      @Down: -> @ @_Down
      @Up: -> @ @_Up

    class DigitalInput ###::implements StateSource< DigitalValue, DigitalValue >###
      ###::
        value: DigitalValue
      ###
      constructor: (@value = DigitalValue.Down()) ->

      sample: ()###: DigitalValue ### -> @value

      update: (input###: DigitalValue###) ->
        @value = input
        null

      keydown: -> @update DigitalValue.Down()

      keyup: -> @update DigitalValue.Up()

    # TODO: implement this! Note that it will have to assert or ensure that only one of the digital
    # inputs will ever be on at a time!
    class DigitalToAnalogSpreader ###::implements StateSource< NormalizedFloat >###
      ###::
        range: FloatRange
        orderedInputs: Array< DigitalInput >
      ###
      constructor: (@range, @orderedInputs) ->
        assert.ok @orderedInputs.length > 0

# StateSet

    ###::
      interface StateSet<K, V> {
        sampleKey(key: K): V;
        updateKey(key: K, value: V): null;
      }
    ###

    # class ContinuousInputSet ###::implements StateSet<  >###

    class KeyCode ###:: implements TypedKey###
      ###::
        value: number
      ###
      constructor: (@value) ->
        assert.ok Number.isInteger @value

      extractValue: -> @value

      computeHash: -> @value

Note that `KeyCode`s may have negative integer `.value`s *(for now)*.

    class DigitalInputSet ###::implements StateSet< KeyCode, DigitalValue >###
      ###::
        inputs: TypedMap< KeyCode, DigitalValue >
      ###
      constructor: (inputs###: Array< [KeyCode, DigitalValue] >###) ->
        @inputs = new TypedMap

        for [keyCode, digitalValue] in inputs
          duplicatePrevious = @inputs.get keyCode
          if duplicatePrevious?
            throw new Error("duplicate inputs registered for #{keyCode}: #{duplicatePrevious} and #{digitalValue}")
          @inputs.set keyCode, digitalValue

      sampleKey: (key###: KeyCode###)###: DigitalValue### -> @inputs.get key

      updateKey: (key###: KeyCode###, value###: DigitalValue###) ->
        prevDigitalValue = @inputs.get key
        prevDigitalValue.setValueFrom value
        null

# WorkingInputSet

`WorkingInputSet` defines the precise API that the rest of the code will use to understand and performantly
manipulate inputs.

    class HierarchicalInputKey
      ###::

      ###

    class SingleLevelInputSet
      ###::

      ###

    class HierarchicalInputSet
      ###::
        mapping: Map< String, any >
      ###

    class WorkingInputSet ###::implements StateSet< ???, ??? >###
      ###::

      ###

      sampleKey: (key###: ???###)###: ???### ->

      updateKey: (key###: ???###, value###: ???###) ->
