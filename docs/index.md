---
layout: home
title: Home
nav_order: 1
---

# claudenv

Switch between Claude Code accounts the same way you switch Python envs or Node versions — a shell function that feels like a native command.

Modeled after `nvm` / `venv` / `jenv`. macOS-first.

## Quick install

```sh
curl -o- https://github.com/1shooperman/claude-env/releases/download/v0.1.2/install.sh | sh
```

Then wire your shell profile — the installer will print the exact lines to add. See [Installation](installation) for full details and options.

---

## How it works

Each env is a directory under `~/.claudenv/envs/<name>/`. Activating an env sets `CLAUDE_CONFIG_DIR` to that directory, which tells Claude Code to read its config and credentials from there instead of the default `~/.claude`.

Because claudenv runs as a **shell function** (not a subprocess), it can export environment variables and modify your prompt directly — the same trick `nvm` uses.

---

## At a glance

| I want to… | Command |
|------------|---------|
| Pick an env interactively | `claudenv` |
| Activate a specific env | `claudenv <name>` |
| Deactivate | `claudenv deactivate` |
| Create a new env | `claudenv config [name]` |
| See all envs | `claudenv list` |
| Delete an env | `claudenv remove <name>` |
| Upgrade claudenv | `claudenv upgrade latest` |
| Uninstall | `claudenv uninstall` |

Full reference → [Commands](commands/)
