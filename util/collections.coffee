# @flow

###::
  export interface TypedKey {
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

  getNow: (key###: K###)###: V### ->
    ret = @get key
    throw new Error("no value found for key #{key.toString()}") if ret is undefined
    # $FlowFixMe
    ret

  set: (key###: K###, value###: V###)###: TypedMap< K, V >### ->
    @tupleMap.set key.computeHash(), [key, value]
    @

  entries: -> @tupleMap.values()

  @fromPairs###::< K: TypedKey, V >###: (pairs###: Array< [K, V] >###)###: TypedMap< K, V >### =>
    map###: TypedMap< K, V >### = new @
    for [k, v] in pairs
      map.set k, v
    map



module.exports = {TypedMap}
