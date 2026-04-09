--!strict

--[=[
	@class Cache
	@private
	@server
	@since 0.1.0

	A simple deduplication cache used to prevent the same event from being processed
	more than once. Keyed by the event's `endTime` timestamp.

	Both the MessagingService subscription (in [AdminAbuse]) and the [Polling] loop
	check this cache before activating an event. If `cache[endTime]` is already `true`,
	the event is skipped.

	```lua
	-- Internal usage:
	if cache[endTime] then
		return -- already processed
	end
	cache[endTime] = true
	```
]=]
local cache: { [number]: boolean } = {}

return cache
