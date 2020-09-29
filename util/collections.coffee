# @flow

assert = require 'assert'
util = require 'util'

stringHash = require 'string-hash'

{Map} = require 'immutable'
###::
  import type {ValueObject} from 'immutable'
###

# TODO: This type does *not* include symbols, because they currently can't be unambiguously
# converted to strings in a way that preserves the uniqueness of each `Symbol()` invocation!!
###::
  export type PrimitiveProductElement = boolean | string | number

  export type ProductElement = TypedKey | PrimitiveProductElement

  export type ProductElementSpecification = {[string]: ProductElement}

  export interface TypedKey {
    productElements(): ProductElementSpecification;
  }

  type ImmutableProductElementMapping = Map< string, (PrimitiveProductElement | ImmutableProductElementMapping) >
###


maybePrimitive = (x###: PrimitiveProductElement | any###)###: ?PrimitiveProductElement### ->
  switch typeof x
    when 'string', 'number', 'boolean' then x
    else null


class ProductKey ###::< K: TypedKey > implements ValueObject###
  ###::
    key: K
    productElements: ImmutableProductElementMapping
  ###
  constructor: (key###: K###) ->
    @key = key
    @mapping = ProductKey._extractRecursiveProducts key.productElements()

  _keyType: ()###: Class<K>### -> @key.constructor

  @_extractRecursiveProducts: (spec###: ProductElementSpecification###)###: ImmutableProductElementMapping### =>
    replacedMapping = for name, value of spec
      replacedValue###: PrimitiveProductElement | ImmutableProductElementMapping### =
        # Don't replace primitive values.
        maybePrimitive(value) ?
        # Recursively extract an immutable mapping if it implements TypedKey, otherwise error!
        @_extractRecursiveProducts (value.productElements?() ? (throw new UnhashableObject (new UnhashableElement value), spec))
      [name, replacedValue]
    new Map replacedMapping

  equals: (other###: any###)###: boolean### ->
    # Assert that the `key` object we were originally provided is the same `class` as the one in
    # `other`, and then compare the immutable maps.
    ((@_keyType() is other._keyType()) and (@mapping.equals other.mapping))

  hashCode: ()###: number### -> @mapping.hashCode()

  toString: -> "Key for #{@_keyType().name}(#{@mapping})"


class UnhashableElement extends Error
  ###::
    obj: any
  ###
  constructor: (obj###: any###) ->
    super "object #{util.inspect obj} was not hashable (does not implement TypedKey and is not a PrimitiveProductElement)!"
    @obj = obj


class UnhashableObject extends Error
  ###::
    childElement: any
    parentObject: any
  ###
  constructor: (elementError###: UnhashableElement###, parentObject###: any###) ->
    super "product object #{util.inspect parentObject} was not hashable due to an unhashable field: #{elementError}"
    @childElement = elementError.obj
    @parentObject = parentObject


module.exports = {ProductKey, UnhashableObject}
