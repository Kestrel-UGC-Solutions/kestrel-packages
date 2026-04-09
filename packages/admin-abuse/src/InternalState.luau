--!strict

--[=[
	@class InternalState
	@private
	@server
	@since 0.1.0

	The shared state container for the Admin Abuse package. Every internal module
	reads from and writes to this single source of truth. Not intended for direct
	use by consumers of the package.
]=]

--[=[
	@prop admin_event State
	@within InternalState

	Observable [State] object tracking the currently active event key. Set to `nil`
	when no event is running.

	@since 0.1.0
]=]

--[=[
	@prop admin_event_trove Trove
	@within InternalState

	A [Trove](https://sleitnick.github.io/RbxUtil/api/Trove) used for cleaning up
	resources associated with the current event. Cleaned automatically whenever the
	active event changes or expires.

	@since 0.1.0
]=]

--[=[
	@prop admin_event_end_time number
	@within InternalState

	Unix timestamp (from `os.time()`) at which the current event expires. Defaults to `0`.

	@since 0.1.0
]=]

--[=[
	@prop admin_event_duration number
	@within InternalState

	Duration in seconds for new events. Defaults to `60`.

	@since 0.1.0
]=]

--[=[
	@prop memstore_update_interval number
	@within InternalState

	How often (in seconds) the [Polling] loop checks MemoryStoreService for
	cross-server event state. Defaults to `5`.

	@since 0.1.0
]=]

--[=[
	@prop messaging_topic string
	@within InternalState

	The MessagingService topic name used for cross-server event broadcasts.
	Defaults to `"AA_TOPIC"`.

	@since 0.1.0
]=]

local State = require(script.Parent.State)
local Trove = require(script.Parent.Parent.Trove)

local state = {}

state.admin_event = State.new()
state.admin_event_trove = Trove.new()
state.admin_event_end_time = 0

state.admin_event_duration = 60

state.memstore_update_interval = 5

state.messaging_topic = "AA_TOPIC"

return state
