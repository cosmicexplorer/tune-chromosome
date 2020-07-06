# @flow

classOf = (x) -> Object.getPrototypeOf(x).constructor

module.exports = {classOf}
