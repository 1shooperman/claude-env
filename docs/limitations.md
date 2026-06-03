---
layout: default
title: Known limitations
nav_order: 6
---

# Known limitations

## No auth flow

`claudenv config` creates the env directory but does not log you in. After creating and activating a new env, run `claude` and complete the authentication flow manually to associate credentials with that env.

Tracked in [#1](https://github.com/1shooperman/claude-env/issues/1).

## WSL / Windows

claudenv is macOS-first. WSL and native Windows are not yet supported.

Tracked in [#2](https://github.com/1shooperman/claude-env/issues/2).

## Powerlevel10k

The `precmd` hook approach does not integrate with p10k's async prompt segments. The env prefix may not appear when using p10k.

Tracked in [#3](https://github.com/1shooperman/claude-env/issues/3).

## Fish shell

Fish uses a different config syntax. Fish support is not currently implemented — contributions welcome.
