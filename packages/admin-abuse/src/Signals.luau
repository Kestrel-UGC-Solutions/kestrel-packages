--!strict

--[=[
	@class Signals
	@private
	@server
	@since 0.1.0

	Central hub for all Signal instances used by the Admin Abuse package. Built on
	[sleitnick/signal](https://sleitnick.github.io/RbxUtil/api/Signal).

	Currently exposes a single signal that is fired by [Boot] whenever a new event
	begins executing.
]=]

local Signal = require(script.Parent.Parent.Signal)

local signals = {}

--[=[
	@prop admin_event_changed Signal
	@within Signals

	Fires when a new admin event starts executing. The callback receives the event
	key (`string`) as its only argument. Exposed publicly via [AdminAbuse].onEventChanged.

	@since 0.1.0
]=]
signals.admin_event_changed = Signal.new()

return signals
