@flow

    stringHash = require 'string-hash'

    ###::
      import type {TypedKey} from '../util/collections';
    ###

# FilterName

    class FilterName ###:: implements TypedKey###
      ###::
        name: string
      ###
      constructor: (name###: string###) ->
        @name = name

      computeHash: -> stringHash @name

# Filter
`Filter`s have controls and convert an input stream to an output stream!

**Filters represent "the state of making and iterating on a sound" as atomically as possible.** By selecting a filter, the user should be able to:
1. immediately hear the exact sound they heard before when last playing the filter, and
2. immediately have the ability to use the exact same InputMapping as when last playing the filter!

Contrast to [`AppState`](../state-machine/operations.html#appstate)!


    class Filter
      ###::
        inputMapping: InputMapping
      ###
      # $FlowFixMe
      constructor: (@inputMapping) ->


# FilterNode
A `FilterNode` is a wrapper for a node in a vast searchable graph of all `Filter`s! This means it contains the information required to effectively index and search filters later, in the finely-tuned `filter-select` view. It will also need to contain sufficient information to allow for `select-filter-parameter` to traverse nodes efficiently.


**Filters are a "sound state", and FilterNodes are an index into a field (TODO: a math field????) to traverse sound states!!!!**


    _filterNodeSeparator = '/'

    ###::
      interface FilterNodeAgglomeration {}

      type _pipeOptions = {|
        source: FilterNode,
        output: FilterNode,
        name?: ?string,
      |}

      type _pipedSourceOutput = {|
        source: FilterNode,
        output: FilterNode,
      |}
    ###

- `name` contains a reference to the entire prototype chain of filters for fuzzy matching at the speed of thought (like emacs buffer searching by name with helm!!!).
    - `name` can also be set afterwards to "pin" or "save" specific filters with short abbreviations.
- `source` and `output` allow traversing sources step by step by walking "between" them.
- `timestamp` enables time travel view (chronological search) through filters!

The `FilterNode` class follows:

    ###::
      type _filterOpts = {|
        filter: Filter,
        name: string,
        source: ?FilterNode,
        output: ?FilterNode,
        timestamp: Date,
      |}
    ###

    class FilterNode
      ###::
        filter: Filter
        name: string
        source: ?FilterNode
        output: ?FilterNode
        timestamp: Date
      ###
      constructor: (opts###: _filterOpts###) ->
        {filter, name, source, output, timestamp} = opts
        @filter = filter
        @name = name
        @source = source
        @output = output
        @timestamp = timestamp


Retrieve the `source` and `output` nodes after asserting that they exist (i.e. that this FilterNode is "active" and has a specified input and output stream).

      assertPipedSourceOutput: ###: _pipedSourceOutput### ->
        # TODO: why would we assume these are correct???
        # assert.ok @source?
        # assert.ok @output?

We cast through any to satisfy Flow here. See https://flow.org/en/docs/types/casting/#toc-type-casting-through-any.

        {source, output} = {@source, @output}
        source2 = (source###: any###)
        output2 = (output###: any###)
        {source: source2, output: output2}

      pipe: (options###: _pipeOptions###) ###: FilterNode### ->
        {source, output, name = null} = options

Immediately after selecting a filter, we expect the node we receive to have been sanitized of input and output. The input and output is **controlled by the user**, *elsewhere!*

        assert.ok not @source?
        assert.ok not @output?

        new FilterNode
          filter: @filter
          name: name ? @name
          source: source
          output: output
          timestamp: new Date

      remap: (inputMapping###: InputMapping###)###: FilterNode### ->
        throw new Error("TODO: unimplemented!!!")


## FilterParameter
This class points somewhere into some nested [`FilterNode`](#filter-node) and into a setting on its contained [`Filter`](#filter). Note that a Filter will have its own InputMapping as well. **RECURSION!**

    class FilterParameter
