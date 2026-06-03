---
layout: default
title: remove
parent: Commands
nav_order: 6
---

# claudenv remove

Delete an env and its directory.

## Usage

```sh
claudenv remove work
```

Prompts for confirmation before deleting.

## What it does

Removes `~/.claudenv/envs/<name>/` and all its contents. This is permanent — any credentials or config stored in that env directory are deleted.

## Errors

| Message | Cause |
|---------|-------|
| `claudenv: no such env "…"` | The named env does not exist |
| `claudenv: cannot remove active env "…"` | Deactivate first with `claudenv deactivate`, then remove |
| `claudenv: cannot remove the reserved "default" env` | `default` is built-in and cannot be removed |
