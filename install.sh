#!/bin/sh
# claudenv install
#
# One-liner remote install (recommended):
#   curl -o-  https://raw.githubusercontent.com/1shooperman/claude-env/main/install.sh | sh
#   wget -qO- https://raw.githubusercontent.com/1shooperman/claude-env/main/install.sh | sh
#
# Specific version (includes integrity check):
#   curl -o-  https://github.com/1shooperman/claude-env/releases/download/v0.1.0/install.sh | sh
#
# Local install (from a cloned repo):
#   sh install.sh

set -e

# ── Version ───────────────────────────────────────────────────────────────────
# Updated automatically by the release workflow — do not edit by hand.
CLAUDENV_VERSION="main"

CLAUDENV_GITHUB_RAW="https://raw.githubusercontent.com/1shooperman/claude-env"
CLAUDENV_RELEASE_BASE="https://github.com/1shooperman/claude-env/releases/download"
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

_claudenv_verify_sha256() {
  local file="$1" sums_file="$2"
  local filename expected actual

  filename="$(basename "$file")"
  # sha256sum/shasum output format: "<hash>  <filename>"
  expected=$(awk -v f="$filename" '$2 == f { print $1 }' "$sums_file" 2>/dev/null)

  if [ -z "$expected" ]; then
    printf 'claudenv: no checksum found for "%s" in SHA256SUMS\n' "$filename" >&2
    return 1
  fi

  if command -v sha256sum > /dev/null 2>&1; then
    actual=$(sha256sum "$file" | awk '{ print $1 }')
  elif command -v shasum > /dev/null 2>&1; then
    actual=$(shasum -a 256 "$file" | awk '{ print $1 }')
  else
    printf 'claudenv: no sha256 utility found — skipping integrity check\n' >&2
    return 0
  fi

  if [ "$actual" != "$expected" ]; then
    printf 'claudenv: integrity check FAILED for "%s"\n' "$filename" >&2
    printf '  expected: %s\n' "$expected" >&2
    printf '  actual:   %s\n' "$actual" >&2
    rm -f "$file"
    return 1
  fi

  printf 'claudenv: integrity check passed\n'
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
  if [ "$CLAUDENV_VERSION" = "main" ]; then
    printf 'Downloading claudenv.sh from GitHub (main branch)...\n'
    printf 'Note: main branch installs carry no integrity guarantee.\n'
    _claudenv_download \
      "${CLAUDENV_GITHUB_RAW}/main/claudenv.sh" \
      "$CLAUDENV_HOME/claudenv.sh"
  else
    printf 'Downloading claudenv.sh %s from release assets...\n' "$CLAUDENV_VERSION"
    _claudenv_download \
      "${CLAUDENV_RELEASE_BASE}/${CLAUDENV_VERSION}/claudenv.sh" \
      "$CLAUDENV_HOME/claudenv.sh"
    _claudenv_download \
      "${CLAUDENV_RELEASE_BASE}/${CLAUDENV_VERSION}/SHA256SUMS" \
      "/tmp/claudenv-SHA256SUMS-$$"
    _claudenv_verify_sha256 "$CLAUDENV_HOME/claudenv.sh" "/tmp/claudenv-SHA256SUMS-$$"
    rm -f "/tmp/claudenv-SHA256SUMS-$$"
  fi
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  cp "$SCRIPT_DIR/claudenv.sh" "$CLAUDENV_HOME/claudenv.sh"
fi

chmod 644 "$CLAUDENV_HOME/claudenv.sh"

# Record installed version for `claudenv version`.
printf '%s\n' "$CLAUDENV_VERSION" > "$CLAUDENV_HOME/version"

# ── Shell profile wiring ──────────────────────────────────────────────────────

# Warn on unsupported shells rather than silently writing a broken config.
case "$(basename "${SHELL:-sh}")" in
  zsh|bash) ;;
  *)
    printf '\nWarning: unsupported shell "%s" — claudenv requires bash or zsh.\n' "${SHELL:-unknown}" >&2
    printf 'For manual setup, add to your shell profile:\n' >&2
    printf '  export CLAUDENV_HOME="%s"\n' "$CLAUDENV_HOME" >&2
    printf '  . "%s/claudenv.sh"\n' "$CLAUDENV_HOME" >&2
    exit 0
    ;;
esac

if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "${SHELL:-sh}")" = "zsh" ]; then
  RC="$HOME/.zshrc"
else
  RC="$HOME/.bashrc"
fi

MARKER='# claudenv'
# shellcheck disable=SC2016  # $HOME must not expand here; written literally into the rc file
SOURCE_LINE='. "$HOME/.claudenv/claudenv.sh"'

# Honour a custom CLAUDENV_HOME: write the literal path rather than $HOME/.claudenv.
if [ "$CLAUDENV_HOME" = "$HOME/.claudenv" ]; then
  # shellcheck disable=SC2016  # $HOME must not expand here; written literally into the rc file
  CLAUDENV_HOME_LINE='export CLAUDENV_HOME="$HOME/.claudenv"'
else
  CLAUDENV_HOME_LINE="export CLAUDENV_HOME=\"${CLAUDENV_HOME}\""
fi

if grep -qF "$MARKER" "$RC" 2>/dev/null; then
  printf 'claudenv: already present in %s — skipping.\n' "$RC"
else
  printf '\n%s\n%s\n%s\n' "$MARKER" "$CLAUDENV_HOME_LINE" "$SOURCE_LINE" >> "$RC"
  printf 'Added claudenv to %s\n' "$RC"
fi

printf '\nDone. Reload your shell:\n'
printf '  source %s\n\n' "$RC"
printf 'Then create your first env:\n'
printf '  claudenv config\n'
