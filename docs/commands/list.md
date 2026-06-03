---
layout: default
title: list
parent: Commands
nav_order: 5
---

# claudenv list

List all configured envs.

## Usage

```sh
claudenv list
```

## Output

```
* work      ← active env
  personal
  default   (~/.claude)
```

`*` marks the currently active env. The `default` env shows its path (`~/.claude`) as a reminder that it maps to your original Claude Code home.

If no envs are configured, you are directed to run `claudenv config`.
