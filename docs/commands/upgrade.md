---
layout: default
title: upgrade
parent: Commands
nav_order: 7
---

# claudenv upgrade

Upgrade claudenv to a specific release or the latest version.

## Usage

```sh
claudenv upgrade latest       # latest GitHub release
claudenv upgrade v1.2.3       # specific version tag
```

## What it does

1. Downloads `claudenv.sh` from the specified GitHub release
2. Verifies the SHA256 checksum against `SHA256SUMS` (if available for that release)
3. Backs up the current `claudenv.sh` to `claudenv.sh.bak`
4. Replaces `~/.claudenv/claudenv.sh` with the new version
5. Writes the version tag to `~/.claudenv/version`

After upgrading, reload your shell to apply the update:

```sh
source ~/.claudenv/claudenv.sh
```

## Requirements

`curl` or `wget` must be available (both ship with macOS).
