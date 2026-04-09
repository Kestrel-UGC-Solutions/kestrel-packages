--!strict

--[=[
	@class EventMultipliers
	@server
	@since 0.1.0

	Holds observable [State] objects that represent gameplay multipliers tied to admin
	events. Event Executors can set these values, and other game systems can observe
	them to apply bonuses while an event is active.

	Accessed via [AdminAbuse].EventMultipliers.

	```lua
	-- Inside an event Executor:
	local AdminAbuse = require(path.to.AdminAbuse)
	AdminAbuse.EventMultipliers.ResourceNodeMultiplier:Set(2)

	-- In a resource node system:
	local multiplier = AdminAbuse.EventMultipliers.ResourceNodeMultiplier:Get()
	local yield = baseYield + (baseYield * multiplier)
	```
]=]

local State = require(script.Parent.State)

local eventMultipliers = {}

--[=[
	@prop ResourceNodeMultiplier State
	@within EventMultipliers

	A [State] object holding a number that represents an additional multiplier
	applied to resource node yields. Defaults to `0` (no bonus).

	Set this inside an event Executor to grant bonus resources during the event,
	and reset it to `0` in the Trove cleanup.

	@since 0.1.0
]=]
eventMultipliers.ResourceNodeMultiplier = State.new(0)

return eventMultipliers
