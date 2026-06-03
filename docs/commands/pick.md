---
layout: default
title: pick (interactive)
parent: Commands
nav_order: 2
---

# claudenv

Run `claudenv` with no arguments to open an interactive env picker.

## Usage

```sh
claudenv
```

Presents a numbered list of envs and a `(cancel)` option. Select a number to activate that env.

If only one env exists, it is activated immediately without prompting.

If no envs are configured, you are directed to run `claudenv config`.
