# @flow

# Declare these implicitly-imported methods from the Cakefile prelude.
###::
declare function invoke(s: string): null;
declare function task(name: string, desc: string, cb: (...args: any) => any): any;
###

# stdlib requires, with some promising hacks.
assert = require 'assert'
fs = require 'fs'
util = require 'util'

_promisifyFirstArg = (f) ->
  promiseF = util.promisify f
  (arg) -> promiseF arg

spawnPromise = do ->
  {spawn} = require 'child_process'
  spawnCmd = ([cmd, argv...], cb) ->
    spawn(cmd, argv, {stdio: 'inherit'})
      .on 'close', (code) ->
        throw new Error("failed to exit successfully: code #{code}") if code != 0
        cb null, code
  _promisifyFirstArg spawnCmd

existsAll = do ->
  promiseExists = _promisifyFirstArg fs.exists
  (paths) -> Promise.all paths.map promiseExists

_renameReturnNewPath = do ->
  promiseRename = util.promisify fs.rename
  (oldPath, newPath, args...) ->
    promiseRename oldPath, newPath, args...
      .then -> newPath

renameAll = (replaceFn) -> (paths) ->
  renameTasks = paths.map (p) -> _renameReturnNewPath p, replaceFn(p)
  Promise.all renameTasks

unlinkAll = do ->
  promiseUnlink = _promisifyFirstArg fs.unlink
  (paths) -> Promise.all paths.map promiseUnlink

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
  Promise.all jsxTransformTasks

# CLI options.
# option '-o', '--output [FILE]', 'file to write to'

# Helper methods.
allCoffeeSourcesPattern = ///^(.*?)(?:\.(?:cjsx|coffee|litcoffee))?$///

# '--bare --no-header' is an official suggestion for flow type checking: see
# http://coffeescript.org/v2/#type-annotations!
compileFiles = do ->
  renameJsOutput = renameAll (f) -> f.replace /\.js$/, '.mjs'
  (paths) ->
    jsOutputPaths = paths.map (p) ->
      p.replace allCoffeeSourcesPattern, (_all, noExtName) -> "#{noExtName}.js"
    spawnPromise ['coffee', '-c', '--bare', '--no-header', ...paths]
      .then -> renameJsOutput jsOutputPaths

# Build tasks.
task 'build', 'build everything', ->
  for subcommand in ['coffee', 'cjsx']
    invoke "build:#{subcommand}"

task 'build:coffee', 'compile all .coffee files', ->
  coffeeSources = await glob '**/*.coffee'
  return if _.isEmpty coffeeSources

  mjsOutputs = coffeeSources.map (f) -> f.replace /\.coffee$/, '.mjs'
  assert.deepEqual mjsOutputs, await compileFiles coffeeSources

task 'build:cjsx', 'compile all .cjsx files', ->
  cjsxSources = await glob '**/*.cjsx'
  return if _.isEmpty cjsxSources

  mjsOutputs = cjsxSources.map (f) -> f.replace /\.cjsx$/, '.mjs'
  assert.deepEqual mjsOutputs, await compileFiles cjsxSources
  renameMjsToJsx = renameAll (f) -> f.replace /\.mjs$/, '.jsx'
  jsxOutputs = await renameMjsToJsx mjsOutputs
  transformJsxToMjs = babelTransformAllFiles (f) -> f.replace /\.jsx$/, '.mjs'
  assert.deepEqual mjsOutputs, await transformJsxToMjs jsxOutputs

task 'check', 'run all tests and static analysis', ->
  invoke 'check:flow'

task 'check:flow', 'run the flow typechecker!', (_options) ->
  # FIXME: 'cake check:flow' will repeatedly fail to see an existing js file created in the previous
  # run unless we 'clean' beforehand.
  invoke 'clean'

  invoke 'build'

  await compileFiles ['Cakefile']
  assert.ok (_promisifyFirstArg fs.exists)('Cakefile.js')

  spawnPromise ['flow', 'check']

task 'clean', 'clean up generated output', ->
  looseJsOrJsxFiles = await glob '**/*.{m,}js{,x}', {ignore: 'node_modules/**'}
  unlinkAll looseJsOrJsxFiles
