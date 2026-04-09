--!strict

--[=[
	@class Polling
	@private
	@server
	@since 0.1.0

	A background loop that periodically reads from MemoryStoreService to discover
	events started by other servers. This is the fallback synchronization mechanism —
	if a server misses the MessagingService broadcast, the Polling loop will pick up
	the event on its next cycle.

	The loop runs every `memstore_update_interval` seconds (default: 5). For each key
	in `pollForKeys`, it:

	1. Reads the stored end-time from MemoryStoreService via [Ping].read
	2. If the event has expired (`now >= endTime`), clears local state and removes the
	   key from the hash map
	3. If the event is still active and not already running locally, activates it
	   (checking [Cache] to avoid duplicates)
]=]

--[=[
	@interface PollingContext
	@within Polling

	Configuration passed to the Polling loop on startup.

	.hash MemoryStoreHashMap -- The MemoryStore hash map to poll
	.read (key: string) -> number? -- Function to read an event's end-time
	.pollForKeys {string} -- Array of event keys to watch
]=]

local events = require(script.Parent.Events)

local state = require(script.Parent.InternalState)
local cache = require(script.Parent.Cache)

export type PollingContext = {
	hash: MemoryStoreHashMap,

	read: (events.GlobalEventKey) -> number?,

	pollForKeys: { events.GlobalEventKey },
}

return function(context: PollingContext)
	local hash = context.hash
	local read = context.read

	while true do
		task.wait(state.memstore_update_interval)

		for _, key in context.pollForKeys do
			local ok, endTime = pcall(read, key)
			if not ok or not endTime then
				continue
			end

			local now = os.time()
			local isActive = state.admin_event:Get() == key

			if now >= endTime then
				if isActive then
					state.admin_event:Set(nil)
				end
				pcall(hash.RemoveAsync, hash, key)
			else
				if not isActive and not cache[endTime] then
					cache[endTime] = true
					state.admin_event_end_time = endTime
					state.admin_event:Set(key)
				end
			end
		end
	end
end
