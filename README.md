# claudenv

Switch between Claude Code accounts the same way you switch Python envs or Node versions — a shell function that feels like a native command.

Modeled after `nvm` / `venv` / `jenv`. macOS-first; see [open issues](https://github.com/1shooperman/claude-env/issues) for the WSL/Windows roadmap.

---

## Installation

**curl:**
```sh
curl -o- https://raw.githubusercontent.com/1shooperman/claude-env/main/install.sh | sh
```

**wget:**
```sh
wget -qO- https://raw.githubusercontent.com/1shooperman/claude-env/main/install.sh | sh
```

**Specific version** (includes SHA256 integrity check):
```sh
curl -o- https://github.com/1shooperman/claude-env/releases/download/v0.1.2/install.sh | sh
```

**From a local clone:**
```sh
git clone git@github.com:1shooperman/claude-env.git
sh claude-env/install.sh
```

> **Note:** Piped installs (curl/wget) are non-interactive and skip shell profile wiring. The installer prints the two lines to add manually — follow those instructions, then reload your shell. Local installs (`sh install.sh`) prompt you before writing to your profile.

After wiring your profile, reload your shell:
```sh
source ~/.zshrc   # or ~/.bashrc
```

**oh-my-zsh users:** oh-my-zsh automatically sources any `.zsh` files in `~/.oh-my-zsh/custom/`. You can symlink claudenv there so it loads as part of the normal oh-my-zsh startup — no manual source line in `.zshrc` required:

```sh
ln -s "$HOME/.claudenv/claudenv.sh" "$HOME/.oh-my-zsh/custom/claudenv.zsh"
```

If you previously ran a local install and answered yes to the profile prompt, remove the `# claudenv` block from `~/.zshrc` to avoid double-sourcing.

---

## How it works

`install.sh` downloads `claudenv.sh` to `~/.claudenv/` and sources it from your shell profile. Because it runs as a **shell function** (not a subprocess), it can export environment variables and modify your prompt directly — the same trick `nvm` uses.

Each env is a directory under `~/.claudenv/envs/<name>/`. Activating an env sets `CLAUDE_CONFIG_DIR` to that directory, which tells Claude Code to read config and credentials from there instead of the default `~/.claude`.

---

## Commands

| Command | Description |
|---|---|
| `claudenv` | Interactive env picker |
| `claudenv <name>` | Activate a named env |
| `claudenv deactivate` | Deactivate the current env |
| `claudenv config [name]` | Create a new env |
| `claudenv list` | List all envs (`*` marks the active one) |
| `claudenv remove <name>` | Delete an env |
| `claudenv uninstall` | Remove claudenv and clean up shell profile |

---

## Prompt integration

When an env is active, your prompt is prefixed with the env name:

```
(work) ~ $
```

**oh-my-zsh**: claudenv registers a `precmd` hook via `add-zsh-hook` so the prefix survives theme redraws. Works with any theme that sets `PROMPT` in a precmd hook (robbyrussell, agnoster, etc.).

> **Note:** Powerlevel10k uses its own async rendering pipeline. See [#3](https://github.com/1shooperman/claude-env/issues/3) for p10k support.

---

## Known limitations / Roadmap

- **No auth flow** — `claudenv config` creates the env directory but does not log you in. You must authenticate separately. See [#1](https://github.com/1shooperman/claude-env/issues/1).
- **WSL / Windows** — not yet supported. See [#2](https://github.com/1shooperman/claude-env/issues/2).
- **Powerlevel10k** — the `precmd` hook approach does not integrate with p10k's async prompt segments. See [#3](https://github.com/1shooperman/claude-env/issues/3).
- **Fish shell** — Fish uses a different config syntax; contributions welcome.

---

## Contributing

PRs welcome. The entire tool is plain shell (`claudenv.sh`) — no build step, no dependencies. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Support

If claudenv saves you time, consider [buying me a coffee](https://buymeacoffee.com/aglflorida). ☕
