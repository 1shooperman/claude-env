---
layout: default
title: deactivate
parent: Commands
nav_order: 3
---

# claudenv deactivate

Deactivate the current env and restore the original `CLAUDE_CONFIG_DIR`.

## Usage

```sh
claudenv deactivate
```

## What it does

- Restores `CLAUDE_CONFIG_DIR` to the value it had before claudenv activated (or unsets it if it was unset)
- Removes the env prefix from your shell prompt
- Clears `CLAUDENV_ACTIVE`

## Errors

| Message | Cause |
|---------|-------|
| `claudenv: no active env` | No env is currently active — nothing to deactivate |
