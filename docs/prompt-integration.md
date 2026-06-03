---
layout: default
title: Prompt integration
nav_order: 5
---

# Prompt integration

When an env is active, claudenv prefixes your shell prompt with the env name:

```
(work) ~ $
```

## How it works

**zsh / oh-my-zsh:** claudenv registers a `precmd` hook via `add-zsh-hook` that runs after your theme sets `PROMPT`, prepending the env prefix. This survives theme redraws and works with any theme that sets `PROMPT` in a `precmd` hook (robbyrussell, agnoster, and others).

**bash:** claudenv modifies `PS1` directly on activate and restores the original `PS1` on deactivate.

## Powerlevel10k

Powerlevel10k uses its own async rendering pipeline that bypasses the standard `precmd` hook approach. The env prefix may not appear reliably with p10k. See [GitHub issue #3](https://github.com/1shooperman/claude-env/issues/3) for the status of p10k support.

## Python venv interaction

If Python venv or another tool also prefixes your prompt, claudenv's prefix always appears outermost (leftmost). Internally, claudenv strips all occurrences of its own prefix before prepending once, so the prefix never accumulates across repeated activations.
