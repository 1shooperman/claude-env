#!/bin/sh
# claudenv install
#
# One-liner remote install (recommended):
#   curl -o-  https://raw.githubusercontent.com/1shooperman/claude-env/main/install.sh | sh
#   wget -qO- https://raw.githubusercontent.com/1shooperman/claude-env/main/install.sh | sh
#
# Local install (from a cloned repo):
#   sh install.sh

set -e

# ── Version ───────────────────────────────────────────────────────────────────
# Updated automatically by the release workflow — do not edit by hand.
CLAUDENV_VERSION="main"

CLAUDENV_GITHUB_RAW="https://raw.githubusercontent.com/1shooperman/claude-env"
CLAUDENV_HOME="${CLAUDENV_HOME:-$HOME/.claudenv}"

# ── Helpers ───────────────────────────────────────────────────────────────────

_claudenv_download() {
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$1" -o "$2"
  elif command -v wget > /dev/null 2>&1; then
    wget -qO "$2" "$1"
  else
    printf 'claudenv: curl or wget is required for remote installation\n' >&2
    return 1
  fi
}

# When piped through curl/wget, $0 is the shell binary name, not a file path.
_claudenv_is_remote() {
  case "$(basename "$0")" in
    sh|bash|dash|zsh|ksh|-sh|-bash) return 0 ;;
    *)                               return 1 ;;
  esac
}

# ── Install runtime ───────────────────────────────────────────────────────────

printf 'Installing claudenv %s to %s...\n' "$CLAUDENV_VERSION" "$CLAUDENV_HOME"

mkdir -p "$CLAUDENV_HOME/envs"

if _claudenv_is_remote; then
  printf 'Downloading claudenv.sh from GitHub...\n'
  _claudenv_download \
    "${CLAUDENV_GITHUB_RAW}/${CLAUDENV_VERSION}/claudenv.sh" \
    "$CLAUDENV_HOME/claudenv.sh"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  cp "$SCRIPT_DIR/claudenv.sh" "$CLAUDENV_HOME/claudenv.sh"
fi

chmod 644 "$CLAUDENV_HOME/claudenv.sh"

# ── Shell profile wiring ──────────────────────────────────────────────────────

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
