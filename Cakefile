# stdlib requires, with some promising hacks.
assert = require 'assert'
child_process = require 'child_process'
fs = require 'fs'
util = require 'util'

multiPromise = (fn) ->
  p = util.promisify fn
  (args) -> await Promise.all args.map(p)

existsAll = multiPromise fs.exists

unlinkAllPossible = multiPromise (path, cb) -> fs.unlink path, (_err) -> cb()

rename = util.promisify fs.rename
renameAll = (replaceFn) -> (paths) ->
  renameTasks = paths.map (p) ->
    newPath = replaceFn p
    (rename p, newPath).then -> newPath
  await Promise.all renameTasks

writeFile = util.promisify fs.writeFile

# 3rdparty requires.
_ = require 'lodash'

glob = util.promisify require('glob').glob

{transformFileAsync: babelTransformFileAsync} = require '@babel/core'
babelTransformAllFiles = (replaceFn) -> (paths) ->
  jsxTransformations = paths.map (p) ->
    newPath = replaceFn p
    (babelTransformFileAsync p).then (transformed) ->
      writeFile(newPath, transformed).then -> newPath
  await Promise.all jsxTransformations

# CLI options.
option '-o', '--output [FILE]', 'file to write to'

# Helper methods.
compileFiles = util.promisify (paths, cb) ->
  child_process.spawn('coffee', ['-c', ...paths]).on 'close', (code) ->
    throw Error("failed to exit successfully: code #{code}") if code != 0
    cb(code)

# Build tasks.
task 'build', 'build everything', (options) ->
  for subcommand in ['coffee', 'cjsx']
    invoke "build:#{subcommand}"

task 'build:coffee', 'do a heckin example', (options) ->
  coffee_sources = await glob '**/*.coffee'
  return if _.isEmpty coffee_sources

  expected_outputs = coffee_sources.map (f) -> f.replace /\.coffee$/, '.js'
  await compileFiles coffee_sources
  assert.ok await existsAll expected_outputs

task 'build:cjsx', 'build cjsx', (options) ->
  cjsx_sources = await glob '**/*.cjsx'
  return if _.isEmpty cjsx_sources

  expected_outputs = cjsx_sources.map (f) -> f.replace /\.cjsx$/, '.js'
  await compileFiles cjsx_sources
  assert.ok await existsAll expected_outputs
  rename_js_to_jsx = renameAll (f) -> f.replace /\.js$/, '.jsx'
  jsx_outputs = await rename_js_to_jsx expected_outputs
  transform_jsx_to_js = babelTransformAllFiles (f) -> f.replace /\.jsx$/, '.js'
  assert.deepEqual expected_outputs, await transform_jsx_to_js jsx_outputs
