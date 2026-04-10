#!/bin/sh
# claudenv install — copies claudenv to ~/.claudenv and wires it into your shell profile.
# Usage: sh install.sh

set -e

CLAUDENV_REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDENV_HOME="${CLAUDENV_HOME:-$HOME/.claudenv}"

printf 'Installing claudenv to %s...\n' "$CLAUDENV_HOME"

mkdir -p "$CLAUDENV_HOME/envs"
cp "$CLAUDENV_REPO_DIR/claudenv.sh" "$CLAUDENV_HOME/claudenv.sh"

# Detect rc file from current shell or $SHELL
if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "${SHELL:-sh}")" = "zsh" ]; then
  RC="$HOME/.zshrc"
else
  RC="$HOME/.bashrc"
fi

MARKER='# claudenv'
SOURCE_LINE='. "$HOME/.claudenv/claudenv.sh"'

if grep -qF "$MARKER" "$RC" 2>/dev/null; then
  printf 'claudenv: already present in %s — skipping.\n' "$RC"
else
  printf '\n%s\nexport CLAUDENV_HOME="$HOME/.claudenv"\n%s\n' \
    "$MARKER" "$SOURCE_LINE" >> "$RC"
  printf 'Added claudenv to %s\n' "$RC"
fi

printf '\nDone. Reload your shell:\n'
printf '  source %s\n\n' "$RC"
printf 'Then create your first env:\n'
printf '  claudenv config\n'
