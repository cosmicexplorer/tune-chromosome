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

COFFEESCRIPT_CHECKOUT = '/Users/dmcclanahan/tools/coffeescript'

coffeeCommandName = "#{COFFEESCRIPT_CHECKOUT}/invoke-coffeescript.zsh"

sassCompilerPath = "node_modules/.bin/sass"

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
# {glob = util.promisify &} = require 'glob'
#
# aka:
# {glob} = require 'glob'; glob = util.promisify glob
#
# aka:
# 'a = b &'
# (which is replaced by:)
# 'a = b a'
#
# in js:
# var glob;
# {glob} = require('glob');
# glob = util.promisify(glob);
unflowify = require 'unflowify'

_babelTransformSingleFile = do ->
  {transformFileAsync} = require '@babel/core'
  (inPath, outPath) ->
    transformFileAsync inPath, {sourceMaps: yes, plugins: ["@babel/plugin-transform-react-jsx"]}
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


recognizedCoffeeSourceExtensions = [
  '.coffee'
  '.litcoffee'
]


matchesCoffeeSourceFile = (f) -> (recognizedCoffeeSourceExtensions.find (ext) -> f.endsWith ext)?

globCoffeeSources = ->
  _.flatten await Promise.all (glob "**/*#{ext}" for ext in recognizedCoffeeSourceExtensions)

globLitcoffeeSources = -> await glob "**/*.litcoffee"

globSassSources = -> await glob "**/*.sass"

generateBundle = (outputFile, inputFiles) ->
  assert.ok inputFiles.every matchesCoffeeSourceFile

  bundleStream = browserify
    entries: inputFiles
    extensions: recognizedCoffeeSourceExtensions
    debug: yes
  .transform (file, opts) -> new Coffeeify file, {
    bare: no
    header: yes
    debug: yes
    literate: (file.match /\.litcoffee$/)?
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
    spawnPromise [coffeeCommandName, '-c', '-m', '-M', '--bare', '--no-header', ...paths]
      .then -> renameJsOutput jsOutputPaths

compileLitcoffee = (paths) ->
  htmlOutputPaths = paths.map (f) -> f.replace /\.litcoffee$/, '.html'
  allPandocInvocations = (_.zip paths, htmlOutputPaths).map ([inF, outF]) ->
    spawnPromise ['pandoc', '-f', 'markdown_github', '-t', 'html', inF, '-o', outF]
  Promise.all allPandocInvocations
    .then -> htmlOutputPaths

compileSass = (paths) ->
  cssOutputPaths = paths.map (f) -> f.replace /\.sass$/, '.css'
  joinedCssInOutArgs = (_.zip paths, cssOutputPaths).map ([inF, outF]) -> "#{inF}:#{outF}"
  spawnPromise [sassCompilerPath, ...joinedCssInOutArgs]
    .then -> cssOutputPaths

# Build tasks.
task 'build', 'build everything', ->
  await Promise.all [
    (invoke 'build:coffee'),
    (invoke 'build:sass'),
    (invoke 'build:litcoffee'),
  ]

selectInvalidatedCompiles = (filenamePairs) -> await for [inF, outF] in filenamePairs
  {mtimeMs: inputFileModificationTime} = await fs.promises.stat inF

  missingOutputFile = no
  {mtimeMs: outputFileModificationTime} = await fs.promises.stat(outF).catch (err) ->
    missingOutputFile = yes
    err

  # If the output file doesn't exist or was last updated before the source file, it's invalid!
  if missingOutputFile or (inputFileModificationTime < outputFileModificationTime)
    [inF, outF]

task 'build:coffee', 'compile all .coffee files', ->
  coffeeSources = await globCoffeeSources()

  mjsOutputs = coffeeSources.map (f) -> f.replace /\.(lit)?coffee$/, '.mjs'

  [invalidatedCoffeeSources = [], invalidatedMjsOutputs = []] =
    _.unzip await selectInvalidatedCompiles (_.zip coffeeSources, mjsOutputs)

  return if _.isEmpty invalidatedCoffeeSources

  assert.deepEqual invalidatedMjsOutputs, await compileFiles invalidatedCoffeeSources

  # Not currently using jsx and this currently will create some issues when using flow types!!!
  # jsxOutputs = await (renameAll (f) -> f.replace /\.mjs$/, '.jsx')(mjsOutputs)
  # assert.deepEqual mjsOutputs, await (
  #   babelTransformAllFiles (f) -> f.replace /\.jsx$/, '.mjs'
  # )(jsxOutputs)

  # # We don't want flow to have to see these!
  # await unlinkAll jsxOutputs

task 'build:sass', 'compile all .sass files', ->
  sassSources = await globSassSources()

  cssOutputs = sassSources.map (f) -> f.replace /\.sass$/, '.css'

  [invalidatedSassSources = [], invalidatedCssOutputs = []] =
    _.unzip await selectInvalidatedCompiles (_.zip sassSources, cssOutputs)

  return if _.isEmpty invalidatedSassSources

  assert.deepEqual invalidatedCssOutputs, await compileSass invalidatedSassSources

task 'build:litcoffee', 'compile all .litcoffee files to html', ->
  litcoffeeSources = await globLitcoffeeSources()
  htmlOutputs = litcoffeeSources.map (f) -> f.replace /\.litcoffee$/, '.html'

  [invalidatedLitcoffeeSources = [], invalidatedHtmlOutputs = []] =
    _.unzip await selectInvalidatedCompiles (_.zip litcoffeeSources, htmlOutputs)

  return if _.isEmpty invalidatedLitcoffeeSources

  assert.deepEqual invalidatedHtmlOutputs, await compileLitcoffee invalidatedLitcoffeeSources

task 'check', 'run all tests and static analysis', ->
  await invoke 'check:flow'

task 'check:flow', 'run the flow typechecker!', ->
  # FIXME: Flow will error out if we don't 'clean' for some reason >=[
  await invoke 'clean'
  await invoke 'build'

  await compileFiles ['Cakefile']
  assert.ok await (_promisifyFirstArg fs.exists)('Cakefile.mjs')

  await spawnPromise ['flow', 'check']

task 'clean', 'clean up generated output', ->
  looseJsOrJsxFiles = glob '**/*.{m,}js{,x}{,.map}', ignore: 'node_modules/**'
  looseCssFiles = glob '**/*.css{,.map}', ignore: 'node_modules/**'
  looseHtmlFiles = glob '**/*.html', ignore: 'index.html'

  Promise.all [looseJsOrJsxFiles, looseCssFiles, looseHtmlFiles]
    .then ([looseJsOrJsxFiles, looseCssFiles, looseHtmlFiles]) ->
      unlinkAll [looseJsOrJsxFiles..., looseCssFiles..., looseHtmlFiles...]

task 'bundle', 'create a single merged javascript bundle', ({output = 'bundle.js'}) ->
  await unlinkIgnoringError output

  await invoke 'build'

  allCoffeeSources = await glob '**/*.{cjsx,coffee}',
    ignore: 'node_modules/**'

  await generateBundle output, allCoffeeSources

task 'setup-git-hooks', 'add a pre-commit hook to the local repo', ->
  gitHooksDir = '.git/hooks'
  await fs.promises.mkdir gitHooksDir, recursive: yes
  preCommitHook = "#{gitHooksDir}/pre-commit"
  await fs.promises.writeFile preCommitHook, """
    #!/usr/bin/env bash

    cake check

    """, mode: 0o777
  console.info "pre-commit hook linked at #{preCommitHook}!"
