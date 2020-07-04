# @flow

assert = require 'assert'

###::
  interface TypedKey {
    computeHash(): number;
  }
###

class TypedMap ###::< K: TypedKey, V >###
  ###::
    tupleMap: Map< number, [K, V] >
  ###
  constructor: ->
    @tupleMap = new Map

  clear: -> @tupleMap.clear()

  size: ()###: number### -> @tupleMap.size

  delete: (key###: K###) ->
    @tupleMap.delete key.computeHash()

  has: (key###: K###)###: boolean### ->
    @tupleMap.has key.computeHash()

  get: (key###: K###)###: ?V### ->
    existing = @tupleMap.get key.computeHash()
    if existing isnt undefined
      [_, value] = existing
      value
    else
      undefined

  set: (key###: K###, value###: V###)###: TypedMap< K, V >### ->
    @tupleMap.set key.computeHash(), [key, value]
    @

  entries: -> @tupleMap.values()


module.exports = {TypedMap}
