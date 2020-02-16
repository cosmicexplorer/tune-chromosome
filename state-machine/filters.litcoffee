    # @flow

A filter $f \in F$ is a function mapping an input stream to an output stream given $u!$, $m!$, and
$c_{f}!$, where $c_{f}$ is the section of the digital "control" strip $c!$ in use by the current
filter $f$.

Each filter $f$ would declare an `InputsRequest` (to be processed at app startup) so that the app knows to map that many inputs for the filter when invoked.

    class InputsRequest
      ###::
        digitalDimensions: number
        analogDimensions: number
      ###
      constructor: (@digitalDimensions, @analogDimensions) ->

    class Filter
      ###::
        inputs: InputsRequest
      ###
      constructor: (@inputs) ->
