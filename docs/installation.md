---
layout: default
title: Installation
nav_order: 2
---

# Installation

## curl (recommended)

Includes a SHA256 integrity check:

```sh
curl -o- https://github.com/1shooperman/claude-env/releases/download/v0.1.2/install.sh | sh
```

Piped installs are non-interactive and skip shell profile wiring. The installer prints the two lines to add manually — follow those instructions, then reload your shell.

## From a local clone

```sh
git clone git@github.com:1shooperman/claude-env.git
sh claude-env/install.sh
```

Local installs prompt before writing to your shell profile.

---

## Shell profile wiring

After install, add the sourcing block the installer printed to your `~/.zshrc` or `~/.bashrc`, then reload:

```sh
source ~/.zshrc   # or ~/.bashrc
```

### oh-my-zsh shortcut

oh-my-zsh auto-sources any `.zsh` file in `~/.oh-my-zsh/custom/`. Symlink claudenv there to skip the manual `source` line:

```sh
ln -s "$HOME/.claudenv/claudenv.sh" "$HOME/.oh-my-zsh/custom/claudenv.zsh"
```

If you previously ran a local install and answered yes to the profile prompt, remove the `# claudenv` block from `~/.zshrc` to avoid double-sourcing.

---

## Upgrading

```sh
claudenv upgrade latest      # latest release
claudenv upgrade v1.2.3      # specific version
```

After upgrading, reload your shell:

```sh
source ~/.claudenv/claudenv.sh
```

## Uninstalling

```sh
claudenv uninstall
```

Removes `~/.claudenv` and cleans up the `# claudenv` block from your shell profile.
