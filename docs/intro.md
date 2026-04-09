---
sidebar_position: 1
---

# Getting Started

Kestrel Packages are a collection of server-side Roblox modules maintained by **Kestrel UGC Solutions** and distributed through our [private Wally registry](https://github.com/Kestrel-UGC-Solutions/wally-index).

## Installation

All packages are installed via [Wally](https://wally.run).

### 1. Configure your Wally registry

Add the Kestrel registry to your `wally.toml`:

```toml
[package]
name = "your-name/your-game"
version = "0.1.0"
registry = "https://github.com/Kestrel-UGC-Solutions/wally-index"
realm = "server"
```

### 2. Add dependencies

Add the packages you need under `[dependencies]`:

```toml
[dependencies]
AdminAbuse = "kestrel/admin-abuse@0.1.0"
```

### 3. Install

```bash
wally install
```

Wally will pull the package and its dependencies into your `Packages/` directory.

## Available Packages

| Package | Version | Description |
| ------- | ------- | ----------- |
| [Admin Abuse](/api/AdminAbuse) | `0.1.0` | Cross-server admin event system with automatic synchronization, expiry, and cleanup. |

## Quick Example

```lua
local AdminAbuse = require(path.to.AdminAbuse)

-- Trigger an event across all servers
AdminAbuse.event("SixSeven")

-- Listen for event changes
AdminAbuse.onEventChanged:Connect(function(eventKey)
    print("Event started:", eventKey)
end)
```
