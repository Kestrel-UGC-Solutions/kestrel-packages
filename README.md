# Kestrel Packages

Server packages for Roblox by [Kestrel UGC Solutions](https://github.com/Kestrel-UGC-Solutions).

Hosted on our [private Wally registry](https://github.com/Kestrel-UGC-Solutions/wally-index).

## Packages

| Package | Wally | Description |
| ------- | ----- | ----------- |
| [Admin Abuse](https://Kestrel-UGC-Solutions.github.io/kestrel-packages/api/AdminAbuse) | `kestrel/admin-abuse@0.1.0` | Cross-server admin event system with automatic synchronization and cleanup. |

## Documentation

Full documentation is available at **[Kestrel-UGC-Solutions.github.io/kestrel-packages](https://Kestrel-UGC-Solutions.github.io/kestrel-packages/)**.

## Adding a New Package

1. Create a new directory under `packages/<package-name>/src/`
2. Add Moonwave doc comments to your Luau source files
3. Add the package's classes to the `[[classOrder]]` section in `moonwave.toml`
4. Add the package to the table above and in `docs/intro.md`
5. Push to `main` — the docs workflow deploys automatically
