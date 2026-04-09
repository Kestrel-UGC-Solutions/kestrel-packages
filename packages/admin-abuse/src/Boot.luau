--!strict

--[=[
	@class Boot
	@private
	@server
	@since 0.1.0

	Handles initialization of the Admin Abuse system. Creates the `AdminAbuse` folder
	in `ReplicatedStorage` and observes internal state changes to run event Executors.

	When an event activates, Boot:
	1. Spawns the event's `Executor` function
	2. Schedules an automatic expiry thread
	3. Registers both with a Trove for clean teardown
	4. Sets attributes on the ReplicatedStorage folder so clients can read event state

	The ReplicatedStorage folder exposes three attributes:
	- `EventName` — the active event key (or nil)
	- `EndTime` — unix timestamp when the event expires
	- `Duration` — the configured event duration in seconds
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local state = require(script.Parent.InternalState)
local signals = require(script.Parent.Signals)

local events = require(script.Parent.Events)

local adminAbuseFolder = Instance.new("Folder")
adminAbuseFolder.Name = "AdminAbuse"
adminAbuseFolder.Parent = ReplicatedStorage

local function onStateChanged(newValue)
	state.admin_event_trove:Clean()

	if newValue == nil then
		adminAbuseFolder:SetAttribute("EventName", nil)
		adminAbuseFolder:SetAttribute("EndTime", nil)
		adminAbuseFolder:SetAttribute("Duration", nil)
		return
	end

	local event = events[newValue]
	if not event or not event.Executor then
		return
	end

	local endTime = state.admin_event_end_time
	local remaining = endTime - os.time()

	if remaining <= 0 then
		state.admin_event:Set(nil)
		return
	end

	local executorThread = task.spawn(event.Executor, state.admin_event_trove)

	state.admin_event_trove:Add(function()
		pcall(task.cancel, executorThread)
	end)

	local expiryThread = task.delay(remaining, function()
		state.admin_event:Set(nil)
	end)

	state.admin_event_trove:Add(function()
		pcall(task.cancel, expiryThread)
	end)

	adminAbuseFolder:SetAttribute("EventName", newValue)
	adminAbuseFolder:SetAttribute("EndTime", endTime)
	adminAbuseFolder:SetAttribute("Duration", state.admin_event_duration)

	task.defer(signals.admin_event_changed.Fire, signals.admin_event_changed, newValue)
end

--[=[
	@function init
	@within Boot

	Starts the Boot module. Begins observing [InternalState].admin_event for changes
	and reacts by running or cleaning up event Executors.

	Called internally by the [Ping] module on startup — you do not need to call this
	yourself.

	@private
	@since 0.1.0
]=]
return function()
	state.admin_event:Observe(onStateChanged, true)
end
