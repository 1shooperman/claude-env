---
layout: default
title: FAQ
nav_order: 9
---

# FAQ

## How do I show the active env as an iTerm2 badge?

claudenv exports the active env name as `CLAUDENV_ACTIVE`. Publish it to iTerm2 as a user variable and point the badge at that variable.

1. In iTerm2, open **Settings > Profiles > General > Badge** and set it to:

   ```
   \(user.claudenv)
   ```

2. After `claudenv <name>`, send the env name as the `claudenv` user variable:

   ```sh
   printf '\e]1337;SetUserVar=claudenv=%s\a' "$(printf '%s' "$CLAUDENV_ACTIVE" | base64)"
   ```

   Put that line in whatever script activates the env, right after the `claudenv <name>` call.

The badge then shows the env name in that session only.

## Why does a new split pane show the previous env's badge?

The badge was set with `SetBadgeFormat`. That escape code changes the badge text of the session's profile, and iTerm2 copies that profile into a split pane, so the pane starts with the old text even though no env is active in it.

Use the user variable approach above instead. User variables are attached to the session, so a new pane starts without `user.claudenv` and its badge is blank until you activate an env there.

Panes that already carry the old badge text keep it, and so do splits made from them, until those panes are closed.

## Does this work outside iTerm2?

No. `SetUserVar` and badges are iTerm2 escape codes. Other terminals ignore them.
