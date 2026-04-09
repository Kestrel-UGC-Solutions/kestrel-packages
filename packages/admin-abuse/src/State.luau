--[=[
	@class State

	A lightweight observable value container. Holds a single value and notifies
	registered callbacks whenever that value changes. Used internally by
	[AdminAbuse] for reactive state management.

	```lua
	local myState = State.new(0)

	myState:Observe(function(value)
		print("Value changed to:", value)
	end)

	myState:Set(42) -- prints "Value changed to: 42"
	```

	@private
	@server
	@since 0.1.0
]=]
local HttpService = game:GetService("HttpService")

local State = {}
State.__index = State

--[=[
	Creates a new State object with the given initial value.

	@param value any -- The initial value (can be nil)
	@return State
	@since 0.1.0
]=]
function State.new(value: any)
	local self = setmetatable({
		value = value,
		callbacks = {},
	}, State)
	return self
end

--[=[
	Updates the stored value. If the new value is different from the current value,
	all registered observer callbacks are invoked with the new value via `task.spawn`.

	If the new value is the same as the current value, this is a no-op.

	@param newVal any -- The new value to store
	@since 0.1.0
]=]
function State:Set(newVal)
	if newVal == self.value then
		return
	end

	self.value = newVal

	for _, callback in self.callbacks do
		task.spawn(callback, self.value)
	end
end

--[=[
	Returns the current stored value.

	@return any
	@since 0.1.0
]=]
function State:Get()
	return self.value
end

--[=[
	Registers a callback that fires whenever the value changes. Optionally invokes
	the callback immediately with the current value.

	Returns an unsubscribe function — call it to stop receiving updates.

	```lua
	local unsubscribe = myState:Observe(function(value)
		print(value)
	end, true) -- true = also fire immediately with current value

	-- Later, to stop observing:
	unsubscribe()
	```

	@param callback (value: any) -> () -- Function to call on value change
	@param getInitial boolean? -- If true, fires the callback immediately with the current value
	@return () -> () -- Unsubscribe function
	@since 0.1.0
]=]
function State:Observe(callback, getInitial: boolean?)
	if getInitial then
		task.spawn(callback, self.value)
	end

	local uid = HttpService:GenerateGUID()
	self.callbacks[uid] = callback

	return function()
		self.callbacks[uid] = nil
	end
end

return State
