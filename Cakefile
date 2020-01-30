# stdlib requires, with some promising hacks.
assert = require 'assert'
child_process = require 'child_process'
fs = require 'fs'
util = require 'util'

multiPromise = (fn) ->
  p = util.promisify fn
  (args) -> await Promise.all args.map(p)

existsAll = multiPromise fs.exists

unlinkAllPossible = multiPromise (path, cb) -> fs.unlink path, -> cb()

_renameReturnNewPath = do ->
  promiseRename = util.promisify fs.rename
  (oldPath, newPath, args...) ->
    promiseRename(oldPath, newPath, args...).then -> newPath

renameAll = (replaceFn) -> (paths) ->
  renameTasks = paths.map (p) -> _renameReturnNewPath p, replaceFn(p)
  await Promise.all renameTasks

_writeFileReturnNewPath = do ->
  promiseWriteFile = util.promisify fs.writeFile
  (path, args...) ->
    promiseWriteFile path, args...
      .then -> path

# 3rdparty requires.
_ = require 'lodash'

glob = util.promisify require('glob').glob

_babelTransformSingleFile = do ->
  {transformFileAsync} = require '@babel/core'
  (inPath, outPath) ->
    transformFileAsync inPath, {plugins: ["@babel/plugin-transform-react-jsx"]}
      .then ({code}) -> _writeFileReturnNewPath outPath, code

babelTransformAllFiles = (replaceFn) -> (paths) ->
  jsxTransformTasks = paths.map (p) -> _babelTransformSingleFile p, replaceFn(p)
  await Promise.all jsxTransformTasks

# CLI options.
# option '-o', '--output [FILE]', 'file to write to'

# Helper methods.
compileFiles = util.promisify (paths, cb) ->
  all_args = ['-c', '--bare', '--no-header', ...paths]
  child_process.spawn 'coffee', all_args
    .on 'close', (code) ->
      throw Error("failed to exit successfully: code #{code}") if code != 0
      cb null, code

# Build tasks.
task 'build', 'build everything', (options) ->
  for subcommand in ['coffee', 'cjsx']
    invoke "build:#{subcommand}"

task 'build:coffee', 'do a heckin example', (options) ->
  coffeeSources = await glob '**/*.coffee'
  return if _.isEmpty coffeeSources

  expectedOutputs = coffeeSources.map (f) -> f.replace /\.coffee$/, '.js'
  await compileFiles coffeeSources
  assert.ok await existsAll expectedOutputs

task 'build:cjsx', 'build cjsx', (options) ->
  cjsxSources = await glob '**/*.cjsx'
  return if _.isEmpty cjsxSources

  expectedOutputs = cjsxSources.map (f) -> f.replace /\.cjsx$/, '.js'
  await compileFiles cjsxSources
  assert.ok await existsAll expectedOutputs
  renameJsToJsx = renameAll (f) -> f.replace /\.js$/, '.jsx'
  jsxOutputs = await renameJsToJsx expectedOutputs
  transformJsxToJs = babelTransformAllFiles (f) -> f.replace /\.jsx$/, '.js'
  assert.deepEqual expectedOutputs, await transformJsxToJs jsxOutputs
