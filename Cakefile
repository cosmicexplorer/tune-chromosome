# @flow

# Declare these implicitly-imported methods from the Cakefile prelude.
###::
declare function invoke(s: string): null;
declare function option(short: string, long: string, desc: string): null;
declare function task(name: string, desc: string, cb: (...args: any) => any): any;
###

# stdlib requires, with some promising hacks.
assert = require 'assert'
fs = require 'fs'
{Transform} = stream = require 'stream'
path = require 'path'
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

unlinkIgnoringError = _promisifyFirstArg (path, cb) ->
  fs.unlink path, -> cb()
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
browserify = require 'browserify'
coffeescript = require 'coffeescript'
convert = require 'convert-source-map'
glob = util.promisify require('glob').glob
# Suggested CoffeeScript syntax improvement:
# {glob: => util.promisify} = require 'glob'
unflowify = require 'unflowify'

_babelTransformSingleFile = do ->
  {transformFileAsync} = require '@babel/core'
  (inPath, outPath) ->
    transformFileAsync inPath, {plugins: ["@babel/plugin-transform-react-jsx"]}
      .then ({code}) -> _writeFileReturnNewPath outPath, code

babelTransformAllFiles = (replaceFn) -> (paths) ->
  jsxTransformTasks = paths.map (p) -> _babelTransformSingleFile p, replaceFn(p)
  Promise.all jsxTransformTasks

# CLI options.
option '-o', '--output [FILE]', 'file to write to'

# Helper methods.
afterStreamFinished = _promisifyFirstArg stream.finished


class ParseError extends SyntaxError
  ### Creates a ParseError from a CoffeeScript SyntaxError modeled after substack's syntax-error
      module.
  ###

  ###::
    annotated: string
    line: number
    column: number
  ###

  constructor: ({@message, location: {first_line, last_line, first_column, last_column}},
                src, file) ->
    super()
    @line = first_line + 1 # cs linenums are 0-indexed
    @column = first_column + 1 # same with columns

    markerLen = 2
    {location: {first_line, last_line, first_column, last_column}} = error
    if first_line == last_line
      markerLen += last_column - first_column

    @annotated = [
      file + ':' + @line,
      src.split('\n')[@line - 1],
      Array(@column).join(' ') + Array(markerLen).join('^'),
      'ParseError: ' + @message
    ].join '\n'

  toString: -> @annotated

  inspect: -> @annotated


allCoffeeSourcesPattern = ///^(.*?)(?:\.(?:cjsx|coffee|litcoffee))?$///


getJsFileBasename = (p) ->
  p.replace allCoffeeSourcesPattern, (_all, noExtName) -> "#{noExtName}.js"


class Coffeeify extends Transform
  ###::
    filename: string
    savedChunks: Array<Buffer>
    compileOptions: {
      ast: boolean,
      sourceMap: boolean,
      inlineMap: boolean,
      filename: string,
      bare: boolean,
      header: boolean,
      inline: boolean,
      literate: boolean,
      transpile: {
        presets: Array<string>,
      },
    }
  ###

  constructor: (@filename, {_flags: {debug: sourceMap = no}, ...moreFlags}) ->
    super()
    @savedChunks = []
    @compileOptions = {
      sourceMap
      bare: yes
      header: no
      ...moreFlags
    }

  _transform: (chunk, enc, cb) ->
    @savedChunks.push chunk
    cb()

  _compile: (source, cb) ->
    try
      compiled = coffeescript.compile source, {
        inline: yes
        literate: no
        ...@compileOptions
      }
    catch e
      error = e
      if e.location
        error = new ParseError e, source, @filename
      cb error
      return

    if @compileOptions.sourceMap
      map = convert.fromJSON compiled.v3SourceMap
      basename = path.basename @filename

      map.setProperty 'file', getJsFileBasename(basename)
      map.setProperty 'sources', [basename]
      map.setProperty 'sourcesContent', [source]

      fullString = "#{compiled.js}\n#{map.toComment()}\n"
      cb null, fullString
    else
      cb null, "#{compiled}\n"

  _flush: (cb) ->
    source = (Buffer.concat @savedChunks).toString()
    @_compile source, (err, res) =>
      @push res unless err
      cb err


generateBundle = do ->
  renameCjsxToCoffee = renameAll (f) -> f.replace /\.cjsx$/, '.coffee'
  (outputFile, inputFiles) ->
    [cjsxSrc, coffeeSrc] = _.partition inputFiles, (f) -> (f.match /\.cjsx$/)?

    newCoffeeSources = await renameCjsxToCoffee cjsxSrc
    allCoffeeSources = [newCoffeeSources..., coffeeSrc...]
    assert.equal inputFiles.length, allCoffeeSources.length

    bundleStream = browserify
      entries: allCoffeeSources
      extensions: ['.coffee']
      debug: yes
    .transform (file, opts) -> new Coffeeify file, {
      bare: no
      header: yes
      transpile:
        presets: ["@babel/env", "@babel/react"]
      ...opts
    }
    .transform unflowify
    .bundle()
    .pipe fs.createWriteStream outputFile

    afterStreamFinished bundleStream
      .then -> outputFile

# '--bare --no-header' is an official suggestion for flow type checking: see
# http://coffeescript.org/v2/#type-annotations!
compileFiles = do ->
  renameJsOutput = renameAll (f) -> f.replace /\.js$/, '.mjs'
  (paths) ->
    jsOutputPaths = paths.map getJsFileBasename
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

task 'check:flow', 'run the flow typechecker!', ->
  # FIXME: 'cake check:flow' will repeatedly fail to see an existing js file created in the previous
  # run unless we 'clean' beforehand.
  invoke 'clean'

  invoke 'build'

  await compileFiles ['Cakefile']
  assert.ok await (_promisifyFirstArg fs.exists)('Cakefile.mjs')

  spawnPromise ['flow', 'check']

task 'clean', 'clean up generated output', ->
  looseJsOrJsxFiles = await glob '**/*.{m,}js{,x}',
    ignore: 'node_modules/**'
  unlinkAll looseJsOrJsxFiles

task 'bundle', 'create a single merged javascript bundle', ({output = 'bundle.js'}) ->
  await unlinkIgnoringError output

  allCoffeeSources = await glob '**/*.{cjsx,coffee}',
    ignore: 'node_modules/**'

  generateBundle output, allCoffeeSources
