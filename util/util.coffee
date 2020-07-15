# @flow


classOf = ###::< T >###(x###: T###)###: Class<T>### ->
  # $FlowFixMe
  Object.getPrototypeOf(x).constructor

module.exports = {classOf}
