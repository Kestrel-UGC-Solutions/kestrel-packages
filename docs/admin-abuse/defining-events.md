---
sidebar_position: 2
---

# Defining Events

Admin Abuse events are defined in the `Events` folder inside the package. Each event needs an `Executor` function — a callback that runs on every server when the event is active.

## Event Structure

Events are accessed by key from the `Events` module. Each event entry should be a table with an `Executor` field:

```lua
-- Events/SixSeven.luau (example)
local Trove = require(path.to.Trove)

return {
    Executor = function(trove: Trove.Trove)
        -- This runs on every server when the event starts.
        -- Use the trove to manage cleanup.

        print("SixSeven event is active!")

        -- Example: double resource node output
        local AdminAbuse = require(script.Parent.Parent)
        AdminAbuse.EventMultipliers.ResourceNodeMultiplier:Set(1)

        trove:Add(function()
            AdminAbuse.EventMultipliers.ResourceNodeMultiplier:Set(0)
        end)
    end,
}
```

## The Executor Function

The `Executor` receives a single argument — a [Trove](https://sleitnick.github.io/RbxUtil/api/Trove) instance. Use it to register cleanup tasks:

- The trove is cleaned automatically when the event expires or is replaced by another event.
- Any spawned threads, connections, or instances added to the trove will be destroyed on cleanup.
- You do **not** need to handle expiry manually.

## GlobalEventKey

The `Events` module exports a `GlobalEventKey` type which is a union of all valid event key strings. When you add a new event, add its key to this type so that `AdminAbuse.event()` gets type-safe autocompletion.

## Triggering Events

Once defined, trigger an event from any server script:

```lua
local AdminAbuse = require(path.to.AdminAbuse)

AdminAbuse.event("SixSeven")
```

This will:
1. Persist the event timing in MemoryStoreService
2. Broadcast it to all servers via MessagingService
3. Run the Executor on every server
4. Automatically clean up after the configured duration (default: 60 seconds)

## Polling for Events

By default, the Polling module watches for specific event keys in MemoryStoreService. To have an event discoverable via polling (for servers that miss the MessagingService broadcast), add its key to the `pollForKeys` array in `Ping.luau`:

```lua
task.defer(polling, {
    pollForKeys = {
        "SixSeven",
        "YourNewEvent", -- add new keys here
    },
})
```
