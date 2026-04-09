--!strict

--[=[
	@class AdminAbuse

	The main entry point for the Admin Abuse package. Provides a simple API to trigger
	timed events that automatically synchronize across all active game servers.

	**Install via Wally:**
	```toml
	[dependencies]
	AdminAbuse = "kestrel/admin-abuse@0.1.0"
	```

	**Basic usage:**
	```lua
	local AdminAbuse = require(path.to.AdminAbuse)

	-- Trigger an event on every server
	AdminAbuse.event("SixSeven")

	-- React to event changes
	AdminAbuse.onEventChanged:Connect(function(eventKey)
		print("Event activated:", eventKey)
	end)
	```

	On require, the module subscribes to MessagingService to receive events broadcast
	by other servers. The subscription retries up to 2 times with a 5-second delay
	between attempts if it fails.

	@server
	@since 0.1.0
]=]

local MessagingService = game:GetService("MessagingService")

local events = require(script.Events)
local state = require(script.InternalState)
local cache = require(script.Cache)
local ping = require(script.Ping)
local signals = require(script.Signals)
local eventMultipliers = require(script.EventMultipliers)

local MAX_SUBSCRIBE_RETRIES = 2
local SUBSCRIBE_RETRY_DELAY = 5

task.defer(function()
	for attempt = 0, MAX_SUBSCRIBE_RETRIES do
		local ok = pcall(function()
			MessagingService:SubscribeAsync(state.messaging_topic, function(data)
				local eventKey = data.Data.Event
				local endTime = data.Data.EndTime

				if not eventKey or not endTime then
					return
				end

				if cache[endTime] then
					return
				end

				local remaining = endTime - os.time()
				if remaining <= 0 then
					return
				end

				cache[endTime] = true
				state.admin_event_end_time = endTime
				state.admin_event:Set(eventKey)
			end)
		end)
		if ok then
			break
		end
		if attempt < MAX_SUBSCRIBE_RETRIES then
			task.wait(SUBSCRIBE_RETRY_DELAY)
		end
	end
end)

local AdminAbuse = {}

--[=[
	Triggers an admin abuse event across all servers. The event is identified by its
	key from the Events module.

	When called, this function:
	1. Validates the event key and its Executor
	2. Persists the event end-time in MemoryStoreService via the Ping module
	3. Broadcasts the event to all servers via MessagingService
	4. Activates the event locally (re-triggers if the same event is already active)

	```lua
	AdminAbuse.event("SixSeven")
	```

	@param eventKey string -- The key identifying which event to trigger
	@since 0.1.0
]=]
function AdminAbuse.event(eventKey: events.GlobalEventKey)
	local event = events[eventKey]

	if not event or not event.Executor then
		return
	end

	local endTime = ping.tap(eventKey)

	MessagingService:PublishAsync(state.messaging_topic, {
		Event = eventKey,
		EndTime = endTime,
	})

	-- Force-reset if the same event is already running so the observer re-fires
	if state.admin_event:Get() == eventKey then
		state.admin_event:Set(nil)
	end

	cache[endTime] = true
	state.admin_event_end_time = endTime
	state.admin_event:Set(eventKey)
end

--[=[
	@prop onEventChanged Signal
	@within AdminAbuse

	A Signal that fires whenever a new admin event begins executing. The callback
	receives the event key as its only argument.

	```lua
	AdminAbuse.onEventChanged:Connect(function(eventKey: string)
		print("New event:", eventKey)
	end)
	```

	@since 0.1.0
]=]
AdminAbuse.onEventChanged = signals.admin_event_changed

--[=[
	@prop EventMultipliers EventMultipliers
	@within AdminAbuse

	Reference to the [EventMultipliers] module. Holds observable State objects
	that represent gameplay multipliers which can be set by event Executors and
	observed by other game systems.

	```lua
	local multiplier = AdminAbuse.EventMultipliers.ResourceNodeMultiplier:Get()
	```

	@since 0.1.0
]=]
AdminAbuse.EventMultipliers = eventMultipliers

--[=[
	@prop Events Events
	@within AdminAbuse

	Reference to the Events module. Contains the table of registered events keyed
	by their `GlobalEventKey`. Each event entry has an `Executor` function.

	@since 0.1.0
]=]
AdminAbuse.Events = events

return AdminAbuse
