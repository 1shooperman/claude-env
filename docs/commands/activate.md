---
layout: default
title: activate
parent: Commands
nav_order: 1
---

# claudenv &lt;name&gt;

Activate a named env.

## Usage

```sh
claudenv work
claudenv personal
claudenv default    # maps to ~/.claude (your original config)
```

## What it does

Sets `CLAUDE_CONFIG_DIR` to `~/.claudenv/envs/<name>/` so Claude Code reads config and credentials from that directory. Updates your shell prompt to show the active env name.

If another env is already active, it is silently deactivated first.

## The `default` env

`claudenv default` is a built-in reserved name that maps `CLAUDE_CONFIG_DIR` to `~/.claude` — your original Claude Code home. It lets you switch back to your primary account without fully deactivating.

## Errors

| Message | Cause |
|---------|-------|
| `claudenv: no such env "…"` | The named env directory does not exist — run `claudenv list` or `claudenv config` to create it |
