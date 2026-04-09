---
sidebar_position: 1
---

# Admin Abuse Overview

**Admin Abuse** is a server-side module that lets you trigger timed "admin abuse" events that automatically synchronize across every active game server. When an event fires, every server runs the event's executor function, and when the timer expires, everything cleans up automatically.

## How the Modules Work Together

The package is composed of several internal modules that each handle a specific responsibility. Here's how they fit together:

```
                      ┌─────────────────┐
                      │   AdminAbuse     │  ← Public API (init.luau)
                      │  .event()       │
                      │  .onEventChanged│
                      └────────┬────────┘
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
   ┌────────▼────────┐ ┌──────▼──────┐ ┌─────────▼────────┐
   │      Ping       │ │   Signals   │ │ EventMultipliers  │
   │  MemoryStore    │ │  Signal hub │ │  State-based      │
   │  read/write     │ │             │ │  multipliers      │
   └────────┬────────┘ └─────────────┘ └──────────────────┘
            │
   ┌────────▼────────┐
   │     Polling      │  ← Polls MemoryStore for cross-server sync
   └────────┬────────┘
            │
   ┌────────▼────────┐
   │      Boot        │  ← Initializes ReplicatedStorage folder
   │                  │     and observes state changes to run executors
   └────────┬────────┘
            │
   ┌────────▼────────┐        ┌──────────────┐
   │  InternalState   │───────▶│    State      │
   │  (shared state)  │        │  (observable  │
   └──────────────────┘        │   values)     │
            │                  └──────────────┘
   ┌────────▼────────┐
   │     Cache        │  ← Deduplication cache
   └──────────────────┘
```

### Module Breakdown

#### AdminAbuse (init.luau)
The public-facing API. Exposes `event()` to trigger events and `onEventChanged` to listen for them. When you call `event()`, it:
1. Writes the event end-time to **MemoryStoreService** via the **Ping** module
2. Publishes the event to all servers via **MessagingService**
3. Updates local **InternalState** to kick off execution

#### State
A lightweight observable value container. Supports `:Get()`, `:Set()`, and `:Observe()`. Used internally by **InternalState** and **EventMultipliers** to hold reactive values that trigger callbacks when changed.

#### InternalState
The shared state container for the entire package. Holds the current active event, the Trove for cleanup, timing configuration, and the MessagingService topic name. Every internal module reads from this single source of truth.

#### Boot
Runs once on startup. Creates an `AdminAbuse` folder in `ReplicatedStorage` with attributes (`EventName`, `EndTime`, `Duration`) so the client can read event state. Observes `InternalState.admin_event` and, when an event activates:
- Spawns the event's **Executor** function
- Schedules automatic expiry
- Wires everything into a **Trove** for clean teardown

#### Ping
Interfaces with **MemoryStoreService**. Provides `read()` to check an event's end-time and `tap()` to write a new end-time. This is how event timing persists across servers — even if the originating server shuts down, other servers can discover the event via the memory store.

#### Polling
A background loop that runs every few seconds (configurable via `InternalState.memstore_update_interval`). It reads from **MemoryStoreService** to discover events that were started on other servers. If it finds an active event this server doesn't know about, it activates it locally. If an event has expired, it cleans up.

#### Cache
A simple `{ [endTime]: true }` table that prevents the same event from being processed twice. Both the MessagingService subscription and the Polling loop check this cache before activating an event.

#### Signals
Houses the package's Signal instances (built on `sleitnick/signal`). Currently exposes `admin_event_changed`, which fires whenever a new event begins executing.

#### EventMultipliers
Holds `State` objects that represent gameplay multipliers tied to admin events. Currently includes `ResourceNodeMultiplier` — a numeric value that other systems can observe to apply bonus resource yields during events.

## Cross-Server Flow

Here's what happens end-to-end when you call `AdminAbuse.event("SixSeven")`:

1. **Ping.tap** writes `endTime` to MemoryStoreService
2. **MessagingService:PublishAsync** broadcasts `{ Event, EndTime }` to all servers
3. The local server updates **InternalState** immediately
4. **Boot**'s observer fires, spawns the Executor, sets ReplicatedStorage attributes, schedules expiry
5. Other servers receive the MessagingService message, validate it, update their local state
6. Servers that miss the message discover the event via **Polling** on the next cycle
7. When `endTime` passes, each server's expiry thread (or Polling loop) clears the event and calls `Trove:Clean()`
