--!strict

--[=[
	@class Ping
	@private
	@server
	@since 0.1.0

	Interfaces with MemoryStoreService to persist event timing across servers. Uses a
	MemoryStoreHashMap keyed by event name, with values being the unix `endTime` timestamp.

	On require, this module:
	1. Defers [Boot] to initialize the system
	2. Defers [Polling] to begin the background sync loop

	The hash map entries expire after `admin_event_duration + 60` seconds as a safety margin.
]=]

local MemoryStoreService = game:GetService("MemoryStoreService")

local events = require(script.Parent.Events)
local state = require(script.Parent.InternalState)

local boot = require(script.Parent.Boot)
local polling = require(script.Parent.Polling)

local ROOT_DIRECTORY = "ping"

task.defer(boot)

local function getHash(): MemoryStoreHashMap
	return MemoryStoreService:GetHashMap(ROOT_DIRECTORY)
end

local function readFromChannel(channel: events.GlobalEventKey): number?
	local hash = getHash()
	return hash:GetAsync(channel)
end

local function writeToChannel(channel: events.GlobalEventKey, value: number)
	local hash = getHash()
	hash:UpdateAsync(channel, function()
		return value
	end, state.admin_event_duration + 60)
end

local ping = {}

--[=[
	@within Ping

	Reads the stored end-time for the given event key from MemoryStoreService.

	Returns `nil` if the key does not exist or has expired.

	@param channel string -- The event key to look up
	@return number? -- The unix end-time timestamp, or nil
	@since 0.1.0
]=]
function ping.read(channel: events.GlobalEventKey): number?
	return readFromChannel(channel)
end

--[=[
	@within Ping

	Writes a new end-time for the given event key to MemoryStoreService and returns it.

	The end-time is calculated as `os.time() + admin_event_duration`. The hash map entry
	is set to expire after `admin_event_duration + 60` seconds.

	@param channel string -- The event key to write
	@return number -- The calculated unix end-time timestamp
	@since 0.1.0
]=]
function ping.tap(channel: events.GlobalEventKey): number
	local endTime = os.time() + state.admin_event_duration
	writeToChannel(channel, endTime)
	return endTime
end

task.defer(polling, {
	hash = getHash(),

	read = function(...)
		return ping.read(...)
	end,

	pollForKeys = {
		"SixSeven",
	},
} :: polling.PollingContext)

return ping
