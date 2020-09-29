# @flow


memoize = ###::< T >### (fn###: () => T###)###: () => T### =>
  value###: any### = undefined
  =>
    if value is undefined
      value = fn()
    (value###: T###)


module.exports = {memoize}
