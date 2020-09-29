# @flow

React = require 'react'
ReactDOM = require 'react-dom'

{ViewSwitcher} = require './frontend/views'
{
  DigitalValue, DiscreteInputEvent, InputEventsStream, InputRegistry,
  RegistryForInputRegistries,
} = require './input/input'


# Serialize input events into a passthrough stream.
inputEvents = new InputEventsStream

window.onkeyup = (event###: KeyboardEvent###) ->
  event.preventDefault()
  fullEvent = DiscreteInputEvent.fromKeyboardEvent event, DigitalValue.Up()
  inputEvents.write fullEvent

window.onkeydown = (event###: KeyboardEvent###) ->
  event.preventDefault()
  fullEvent = DiscreteInputEvent.fromKeyboardEvent event, DigitalValue.Down()
  inputEvents.write fullEvent


# Mount the react object to the DOM.
reactStart = (elementId###: string###) ->
  rootDiv = document.getElementById("##{elementId}") ? throw new Error "could not find element ##{elementId}!"
  ReactDOM.render(
    <ViewSwitcher registries={new RegistryForInputRegistries} eventsStream={inputEvents} />,
    rootDiv)

window.onload = -> reactStart 'root'
