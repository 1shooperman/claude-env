---
layout: default
title: config
parent: Commands
nav_order: 4
---

# claudenv config

Create a new env.

## Usage

```sh
claudenv config           # prompts for a name
claudenv config work      # creates env named "work"
```

## What it does

Creates `~/.claudenv/envs/<name>/`. After creation, you are prompted to activate it immediately.

**claudenv does not log you in.** Creating an env only makes the directory. You must authenticate separately by running `claude` while the env is active and following the login flow. See [known limitations](../limitations#no-auth-flow).

## Naming rules

- Must start with a letter or digit
- Allowed characters: letters, numbers, `-`, `_`
- `default` is reserved

## Errors

| Message | Cause |
|---------|-------|
| `claudenv: env "…" already exists` | Env directory is already present — offers to activate instead |
| `claudenv: invalid name "…"` | Name violates the naming rules above |
| `claudenv: "default" is a reserved env` | Use `claudenv default` to activate the built-in default env |
