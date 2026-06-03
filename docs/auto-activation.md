---
layout: default
title: Auto-activation
nav_order: 4
---

# Auto-activation

claudenv can switch envs automatically based on which directory you're in.

## Setup

Place a `.claudenvrc` file containing an env name in any directory:

```sh
echo "work" > /path/to/my-project/.claudenvrc
```

When you `cd` into that directory (or any subdirectory), claudenv activates the named env. When you leave the directory tree, it deactivates automatically — but only if the activation was automatic. Manually activated envs are left alone.

## How it works

claudenv registers a directory-change hook (`chpwd` in zsh, `PROMPT_COMMAND` in bash). On each directory change, it walks up the filesystem from `$PWD` looking for the nearest `.claudenvrc`. If found, it reads the env name and activates it. If no `.claudenvrc` is found and an auto-activated env is currently active, it deactivates.

## Notes

- The hook walks up to the filesystem root, so a `.claudenvrc` in a parent directory applies to all subdirectories unless overridden by a closer `.claudenvrc`
- The env named in `.claudenvrc` must already exist — create it with `claudenv config <name>` first
- An empty `.claudenvrc` is ignored
