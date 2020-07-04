@flow

    assert = require 'assert'

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

      @Zero: -> new @ 0
      @One: -> new @ 1

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
        null

Then we define a `DigitalInput`.

    class DigitalValue
      ###::
        value: Symbol
      ###
      constructor: (@value) ->
        # $FlowFixMe
        assert.ok (@value is DigitalValue._Down) or (@value is DigitalValue._Up)

      setValueFrom: (other###: DigitalValue###) ->
        @value = other.value
        null

      # $FlowFixMe
      @_Down = Symbol 'keycode-down'
      # $FlowFixMe
      @_Up = Symbol 'keycode-up'
      @Down: ->
        # $FlowFixMe
        new @ DigitalValue._Down
      @Up: ->
        # $FlowFixMe
        new @ DigitalValue._Up

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
    # class DigitalToAnalogSpreader ###::implements StateSource< NormalizedFloat >###
    #   ###::
    #     range: FloatRange
    #     orderedInputs: Array< DigitalInput >
    #   ###
    #   constructor: (@range, @orderedInputs) ->
    #     assert.ok @orderedInputs.length > 0
